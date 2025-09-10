import 'package:easy_rich_editor/src/core/api/document/history.dart';
import 'package:easy_rich_editor/src/core/api/document/path/path.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import '../../../../easy_rich_editor.dart';
import 'nodes/node_iterator.dart';

class EasyDocument {
  EasyDocument(
    this.root, {
    EasyHistory? records,
    int maxRecordLimit = EasyHistory.maxRecordOperations,
  }) {
    _initializeHistory(
      records: records,
      maxRecordLimit: maxRecordLimit,
    );
  }

  EasyDocument.json(
    Map<String, dynamic> json, {
    bool jsonHasCachedData = false,
    Object? Function(Object? v)? deserializeValue,
    EasyHistory? records,
    int maxRecordLimit = EasyHistory.maxRecordOperations,
  }) : root = Node.fromJson(
          json,
          deserializeValue: deserializeValue,
          jsonHasCachedData: jsonHasCachedData,
        ) {
    _initializeHistory(
      records: records,
      maxRecordLimit: maxRecordLimit,
    );
  }

  EasyDocument.root({
    required List<Node> nodes,
    EasyHistory? records,
    int maxRecordLimit = EasyHistory.maxRecordOperations,
  }) : root = Node.root(children: nodes) {
    _initializeHistory(
      records: records,
      maxRecordLimit: maxRecordLimit,
    );
  }

  void _initializeHistory({
    required EasyHistory? records,
    required int maxRecordLimit,
  }) {
    assert(
        maxRecordLimit >= 0,
        'max limit of record '
        'operations must be less or '
        'greater than zero');
    history = records ?? EasyHistory(maxLimitOfRecords: maxRecordLimit);
  }

  /// The root source of every Node used into the Tree
  final Node root;
  late final EasyHistory history;

  /// A simple register with all the limiters.
  static final Map<String, Limiter> _limiters = <String, Limiter>{
    EmbedKeys.key: EmbedLimiter.instance(),
    ParagraphKeys.key: ParagraphLimiter.instance(),
  };

  /// A simple register with all the extractors.
  static final Map<String, NodeExtractor> _extractors = <String, NodeExtractor>{
    ParagraphKeys.key: ParagraphNodeExtractor.instance,
    EmbedKeys.key: EmbedNodeExtractor.instance,
  };

  bool canNodeAcceptTypeValue(Node rootOwner, Node node, Type t) {
    final NodeExtractor? extractor = _extractors[rootOwner.type];
    if (extractor == null) {
      throwUnsupportedType(rootOwner.type);
    }

    return extractor!.canNodeHaveValueType(node, t);
  }

  void registerLimiters(List<Map<String, Limiter>> customLimiters) {}
  void registerExtractors(List<Map<String, NodeExtractor>> customExtractors) {}

  static Limiter? getLimiter(Node node) {
    final String key = (node.jumpToParentExceptRoot() ?? node).type;
    return _limiters[key];
  }

  static NodeExtractor? getExtractor(Node node) {
    final String key = (node.jumpToParentExceptRoot() ?? node).type;
    return _extractors[key];
  }

  Node? query(
    String id, {
    bool deep = true,
    String? targetId,
  }) {
    if (targetId == null) {
      return root.findById(id, deep: deep);
    }

    // normally the root parent of the node to search
    final Node? targetNode = root.findById(targetId);
    if (targetNode == null) {
      return null;
    }
    return targetNode.findById(id, deep: deep);
  }

  NodeCursorPosLocation queryOffset(
    int cursorPos, {
    @experimental bool strict = false,
  }) {
    if (strict) {
      // at this point, we get just the parent that contains
      // the node for this offset
      final NodeCursorPosLocation parentLocation =
          root.queryPosition(cursorPos, inclusive: true);

      if (parentLocation.notFoundLocation || parentLocation.found) {
        return parentLocation;
      }

      if (parentLocation.node!.isTableBlock) {}

      // at this point, we get the line that contains our
      // value
      final NodeCursorPosLocation childLocation = parentLocation.node!
          .queryPosition(parentLocation.locationOffset, inclusive: true);

      if (childLocation.notFoundLocation || childLocation.found) {
        return childLocation;
      }

      // if found the node, but not the fragment
      // this probably means
      if (childLocation.foundButNotFragment) {
        final NodeCursorPosLocation effectiveLocation = childLocation
            .location!.node
            .queryOffset(childLocation.locationOffset);

        if (effectiveLocation.found) {
          return effectiveLocation;
        }
      }

      return childLocation;
    }

    return root.queryPosition(cursorPos);
  }

  List<Node> querySelectedNodes(NodeSelection selection) {
    if (selection.selectedNodes != null) {
      return selection.selectedNodes!;
    }

    if (selection.isCollapsed) {
      return <Node>[selection.start.node];
    }

    final NodeSelection normalizedSelection = selection.normalized;

    final List<Node> nodes = NodeIterator(
      startNode: normalizedSelection.start.node,
      endNode: normalizedSelection.end.node,
    ).toList();

    assert(
      nodes.isNotEmpty,
      "Failed to found Nodes between "
      "[${normalizedSelection.start.node.id}] and "
      "[${normalizedSelection.end.node.id}]",
    );

    return nodes;
  }

  /// Queries the child [Node] at [offset] in this [Node].
  (List<Node>, bool) collectNodesUntilOffset(Node node, int cursorPos) {
    if (cursorPos < 0 || cursorPos > node.dataLength) {
      return (<Node>[], true);
    }

    final List<Node> nodes = <Node>[];

    for (final Node child in node.children) {
      final int len = child.dataLength;
      if (cursorPos < len) {
        nodes.add(child);
        cursorPos -= len - (len - cursorPos);
        break;
      }
      nodes.add(child);
      cursorPos -= len;
    }

    return (<Node>[], cursorPos > 0);
  }

  /// Find the Node at the full path passed
  ///
  /// path must be always normalized
  /// (source as first element, and the element as the last one)
  Node? queryPath(NodeDepthPath path) {
    Node? node = root;
    assert(path.isNotEmpty, 'path cannot be empty');
    for (int p in path) {
      if (node == null) {
        return null;
      }
      // traverse always getting the child at the path
      // and setting the child as the new node result
      node = node.elementAtOrNull(p);
    }

    return node;
  }

  List<NodeValueLocation> queryValue(
    Object value, {
    bool caseSensitive = false,
  }) {
    assert(
      value is String || value is Map,
      "the unique values supported for queries are Strings and Maps",
    );
    final List<NodeValueLocation> locations = <NodeValueLocation>[];

    root.forEach((Node rootNode, int rootIndex, VoidCallback shouldBreak) {
      // since we are searching the nodes based on the path
      // we can just redefining its path if them required
      //
      // Never should happen this, but, it's for safety
      rootNode.updatePathsIfNeeded(rootIndex, <int>[rootIndex]);
      final NodeExtractor? extractor = _extractors[rootNode.type];
      if (extractor == null) throwUnsupportedType(rootNode.type);
      final List<NodeValueLocation> location = extractor!.queryValues(
        rootNode,
        value,
        getLimiter(rootNode)!,
        path: <int>[rootIndex],
        caseSensitive: caseSensitive,
      );

      locations.addAll(location);
    });

    return <NodeValueLocation>[...locations];
  }

  bool addNode(
    Node node, {
    List<int>? paths,
  }) {
    if (paths != null) {
      final Node? queryNode = queryPath(paths);
      if (queryNode == null) return false;
      queryNode.insertNode(node);
      return true;
    }
    root.insertNode(node);
    return false;
  }

  /// Insert at the start of the [node] at [path] provided.
  ///
  /// The [path] must match with a block node.
  bool insertAtStart(
    Node node, {
    NodeDepthPath path = const <int>[],
  }) {
    if (path.isEmpty) {
      return insertNode(
        node,
        path: <int>[0],
        after: false,
      );
    }
    final Node? queryNode = queryPath(path);
    if (queryNode == null) return false;
    assert(
        queryNode.canAddOrRemovedChildren,
        'node cannot '
        'modify children length. '
        'Found => ${queryNode.shortInfo()}');
    queryNode.first.insertBefore(node);
    return true;
  }

  /// Insert at the end of the [node] at [path] provided.
  ///
  /// The [path] must match with a block node.
  bool insertAtEnd(
    Node node, {
    NodeDepthPath path = const <int>[],
  }) {
    if (path.isEmpty) return addNode(node);
    final Node? queryNode = queryPath(path);
    if (queryNode == null) return false;
    assert(
        queryNode.canAddOrRemovedChildren,
        'node cannot '
        'modify children length. '
        'Found => ${queryNode.shortInfo()}');
    queryNode.last.insertAfter(node);
    return true;
  }

  /// Insert the specified [node] to the [path] provided.
  ///
  /// - [after]: Determines where will be inserted the [node] at the specified [path]
  ///
  /// If [path] isn't provided, just add to the end of the tree.
  bool insertNode(
    Node node, {
    List<int> path = const <int>[],
    bool after = false,
  }) {
    if (path.isEmpty) return addNode(node);
    final Node? queryNode = queryPath(path);
    if (queryNode == null) return false;
    after ? queryNode.insertAfter(node) : queryNode.insertBefore(node);
    return true;
  }

  bool deleteNodesBySelection(NodeSelection selection) {
    throw UnimplementedError();
  }

  Node? getSelectedNode(NodeSelection selection) {
    throw UnimplementedError();
  }

  bool moveNodeTo(
    Node node,
    int path, {
    bool internally = true,
  }) {
    throw UnimplementedError();
  }

  bool moveNodes(List<Node> nodes, int to, {bool after = false}) {
    assert(nodes.isNotEmpty, 'nodes must not be empty');
    throw UnimplementedError();
  }

  void throwUnsupportedType(Object arg) {
    throw UnsupportedError(
      "The extractor for $arg"
      " is not registered. Contact to the "
      "maintainer or report the "
      "issue in the official repository",
    );
  }
}
