import 'dart:collection';
import 'package:easy_rich_editor/src/core/api/modifiers/table_modifier.dart';
import 'package:easy_rich_editor/src/core/api/operations/transactions.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

import '../../../../easy_rich_editor.dart';
import '../limiters/table_limiter.dart';

class EasyDocument {
  EasyDocument(
    this.root, {
    EasyHistory? records,
    int maxRecordLimit = EasyHistory.maxRecordOperations,
  }) {
    assert(
      root.isRootOwner,
      'expected '
      'root node type. '
      'Found => ${root.shortInfo()}',
    );
    _initializeHistory(
      records: records,
      maxRecordLimit: maxRecordLimit,
    );
  }

  EasyDocument.fromJson(
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

  EasyDocument.fromNodes({
    required List<Node> nodes,
    EasyHistory? records,
    int maxRecordLimit = EasyHistory.maxRecordOperations,
  }) : root = Node.root(children: nodes) {
    assert(
      nodes.every((Node e) => e.isBlockNode),
      'all the '
      'nodes into the iterable '
      'passed must be blocks',
    );
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
    ParagraphKeys.key: ParagraphLimiter.instance(),
    EmbedKeys.key: EmbedLimiter.instance(),
    TableKeys.key: TableLimiter.instance(),
  };

  /// A simple register with all the extractors.
  static final Map<String, NodeExtractor<dynamic>> _extractors =
      <String, NodeExtractor<dynamic>>{
    ParagraphKeys.key: ParagraphNodeExtractor.instance,
    EmbedKeys.key: EmbedNodeExtractor.instance,
    TableKeys.key: TableNodeExtractor.instance,
  };

  /// A simple register with all the modifiers.
  static final Map<String, NodeModifier> _modifiers = <String, NodeModifier>{
    ParagraphKeys.key: DefaultNodeModifier.instance,
    EmbedKeys.key: DefaultNodeModifier.instance,
    TableKeys.key: TableModifier.instance,
  };

  /// Returns the first child in the document tree
  Node? get first => root.firstChild;

  /// Returns the last child in the document tree
  Node? get last => root.lastChild;

  /// Returns the amount of children in the document
  int get length => root.length;

  /// Returns the document text length
  int get textLength => root.toPlainText().length;

  void undo() {
    if (!history.hasUndo) return;
    final EasyOperation undoOp = history.undo();
    apply(
      Transactions(
        operations: Queue<EasyOperation>.from(
          <EasyOperation>[undoOp],
        ),
      ),
    );
  }

  void redo() {
    if (!history.hasRedo) return;
    final EasyOperation redoOp = history.redo();
    apply(
      Transactions(
        operations: Queue<EasyOperation>.from(
          <EasyOperation>[redoOp],
        ),
      ),
    );
  }

  // If the operation comes from remote
  // we just apply the change
  bool apply(
    Transactions transaction, {
    bool recordUndo = true,
    bool recordRedo = false,
  }) {
    bool executed = false;
    for (EasyOperation v in transaction.operations) {
      if (recordUndo || recordRedo) {
        if (v.isRemote) continue;
        history.push(
          v,
          undo: recordUndo,
        );
      }
      final Node? node = queryPath(v.selection.startPath);
      assert(
        node != null,
        'expected defined node, but found null at ${v.selection}',
      );
      executed = node!.receiveDelta(v.toDelta()).executed;
    }
    return executed;
  }

  DeltaChangeResult applyDelta(DeltaNode delta) {
    final Node? loc = queryPath(delta.selection.startPath);
    if (loc != null) {
      if (!delta.selection.isCollapsed) {}
      return loc.receiveDelta(
        delta,
        modifier: _modifiers[loc.jumpToParentExceptRoot()!.type] ??
            NodeModifier.defaultModifier,
      );
    }
    return DeltaChangeResult.noExecution();
  }

  static Limiter? getLimiter(Node node) {
    final String key = (node.jumpToParentExceptRoot() ?? node).type;
    return _limiters[key];
  }

  static NodeExtractor<dynamic>? getExtractor(Node node) {
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
            .queryPosition(childLocation.locationOffset);

        if (effectiveLocation.found) return effectiveLocation;
      }

      return childLocation;
    }

    return root.queryPosition(cursorPos);
  }

  List<Node> getSelectedNodes(NodeSelection selection) {
    if (selection.selectedNodes != null) {
      return selection.selectedNodes!;
    }

    final NodeSelection normalizedSelection = selection.normalized;
    final Node? start = queryPath(normalizedSelection.startPath);
    assert(
        start != null,
        'expected start node, but found '
        'a bad path reference '
        'in selection: $normalizedSelection');

    if (selection.isCollapsed) {
      return <Node>[start!];
    }

    final Node? end = queryPath(normalizedSelection.endPath);
    assert(
        end != null,
        'expected start node, but found '
        'a bad path reference '
        'in selection: $normalizedSelection');

    final List<Node> nodes = NodeIterator(
      startNode: start!,
      endNode: end!,
    ).toList();

    assert(
      nodes.isNotEmpty,
      "Failed to found Nodes between "
      "[${start.id}] and "
      "[${end.id}]",
    );

    return nodes;
  }

  /// Find the Node at the full path passed
  ///
  /// path must be always normalized
  /// (source as first element, and the element as the last one)
  Node? queryPath(NodeDepthPath path) {
    Node? node = root;
    assert(path.isNotEmpty, 'path cannot be empty');
    for (int p in path) {
      if (node == null) return null;
      node = node.elementAtOrNull(
        p,
      );
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
      final NodeExtractor<dynamic>? extractor = _extractors[rootNode.type];
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
