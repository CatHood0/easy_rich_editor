import 'package:easy_rich_editor/src/core/api/document/nodes/node_iterator.dart';
import 'package:easy_rich_editor/src/core/api/document/path/path.dart';
import 'package:easy_rich_editor/src/core/limiters/embed_limiter.dart';
import 'package:flutter/cupertino.dart';
import 'package:easy_rich_editor/easy_rich_editor.dart';
import 'package:meta/meta.dart';

import '../../internal.dart';

@internal
class Tree extends ValueNotifier<Node> implements TreeOperations {
  Tree(this.root) : super(root);

  factory Tree.json(Map<String, dynamic> json) {
    return Tree(Node.root());
  }

  factory Tree.root({
    required List<Node> nodes,
  }) {
    return Tree(
      Node.root(
        children: nodes,
      ),
    );
  }

  /// The root source of every Node used into the Tree
  final Node root;
  final FixedListLength changes =
      FixedListLength(operations: <EasyOperation>[]);

  /// A simple register with all the limiters.
  ///
  /// Typically, this is used when we need to traverse
  /// to get text info, and we need the specifications
  /// of how works that node type
  static final Map<String, Limiter> _limiters = <String, Limiter>{
    EmbedKeys.key: EmbedLimiter.instance(),
    ParagraphKeys.key: ParagraphLimiter.instance(),
  };

  /// A simple register with all the extractors.
  ///
  /// Typically, this is used when we need to get values
  /// from a Node, since every Node has a different way to save
  /// its content, we need implement it's own extractor
  static final Map<String, NodeExtractor> _extractors = <String, NodeExtractor>{
    // prs
    ParagraphKeys.key: ParagraphNodeExtractor.instance,
    ParagraphKeys.lineKey: ParagraphNodeExtractor.instance,
    // embeds
    EmbedKeys.key: EmbedNodeExtractor.instance,
    EmbedKeys.childrenKey: EmbedNodeExtractor.instance,
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

  /// TODO: verify that the key exist
  static Limiter? getLimiter(String key) {
    return _limiters[key];
  }

  static NodeExtractor? getExtractor(String key) {
    return _extractors[key];
  }

  @override
  Node? query(
    String id, {
    bool deep = true,
    String? targetId,
    bool strict = true,
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

  @override
  NodeCursorPosLocation queryOffset(
    int cursorPos, {
    @experimental bool strict = false,
  }) {
    if (strict) {
      // at this point, we get just the parent that contains
      // the node for this offset
      final NodeCursorPosLocation parentLocation = root.queryPosition(
        cursorPos,
        includeLastNode: false,
      );

      if (parentLocation.notFoundLocation) {
        return parentLocation;
      }

      // at this point, we get the line that contains our
      // value
      final NodeCursorPosLocation childLocation =
          parentLocation.location!.node.queryPosition(
        parentLocation.locationOffset,
        includeLastNode: true,
      );

      if (childLocation.notFoundLocation) {
        return parentLocation;
      }

      // if found the node, but not the fragment
      // this probably means
      if (childLocation.foundButNotFragment) {
        final NodeCursorPosLocation effectiveLocation = childLocation
            .location!.node
            .queryFragments(childLocation.locationOffset);

        if (effectiveLocation.found) {
          return effectiveLocation;
        }
      }

      return childLocation;
    }

    return root.queryPosition(
      cursorPos,
      includeLastNode: false,
    );
  }

  @override
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
      return ([], true);
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
  @override
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

  @override
  List<NodeValueLocation> queryValue(
    Object value, {
    bool caseSensitive = false,
  }) {
    assert(
      value is String || value is Map,
      "the unique values supported for queries are Strings and Maps",
    );
    final List<NodeValueLocation> locations = <NodeValueLocation>[];

    root.forEach((rootNode, rootIndex) {
      // since we are searching the nodes based on the path
      // we can just redefining its path if them required
      //
      // Never should happen this, but, it's for safety
      rootNode.updatePathsIfNeeded(rootIndex, <int>[]);
      final NodeExtractor? extractor = _extractors[rootNode.type];
      if (extractor == null) {
        throwUnsupportedType(rootNode.type);
      }
      final List<NodeValueLocation> location = extractor!.getLocationsOfValue(
        rootNode,
        value,
        getLimiter(rootNode.type)!,
        path: <int>[rootIndex],
        caseSensitive: caseSensitive,
      );

      locations.addAll(location);
    });

    return <NodeValueLocation>[...locations];
  }

  List<Node> queryNodes(
    List<String> ids, {
    bool deep = true,
    String? targetId,
  }) {
    final List<Node> nodes = [];
    for (String id in ids) {
      final Node? node = query(
        id,
        deep: deep,
        targetId: targetId,
      );
      if (node != null) {
        nodes.add(node);
      }
    }
    return nodes;
  }

  @override
  bool addNode(
    Node node, {
    List<int>? paths,
    bool after = false,
  }) {
    if (paths != null) {
      final Node? queryNode = queryPath(paths);
      if (queryNode == null) return false;
      if (after) {
        queryNode.insertAfter(node);
        return true;
      }
      queryNode.insertBefore(node);
      return true;
    }
    root.insertNode(node);
    return false;
  }

  bool insertAtStart(Node node) {
    return addNode(node, after: false, paths: [0]);
  }

  bool insertAtEnd(Node node) {
    return addNode(node, after: true, paths: [root.length - 1]);
  }

  @override
  bool insertNode(Node node, {List<int> path = const <int>[]}) {
    // TODO: implement insertNode
    throw UnimplementedError();
  }

  @override
  bool insertNodeAtRoot(Node node, {int path = -1}) {
    // TODO: implement insertNodeAtRoot
    throw UnimplementedError();
  }

  @override
  bool insertText(TextSelection selection) {
    // TODO: implement insertText
    throw UnimplementedError();
  }

  @override
  bool insertTextAtNode(Node target, String text, List<int> path) {
    // TODO: implement insertTextAtNode
    throw UnimplementedError();
  }

  @override
  bool deleteNodesBySelection(TextSelection selection) {
    // TODO: implement deleteNodesBySelection
    throw UnimplementedError();
  }

  @override
  bool deleteText(TextSelection selection) {
    // TODO: implement deleteText
    throw UnimplementedError();
  }

  @override
  Node? getSelectedNode(TextSelection selection) {
    // TODO: implement getSelectedNode
    throw UnimplementedError();
  }

  @override
  String getTextAtSelection(TextSelection selection) {
    // TODO: implement getTextAtSelection
    throw UnimplementedError();
  }

  @override
  bool moveNodeTo(Node node, int path, {bool internally = true}) {
    // TODO: implement moveNodeTo
    throw UnimplementedError();
  }

  @override
  bool moveNodes(List<Node> nodes, int to, {bool after = false}) {
    // TODO: implement moveNodes
    throw UnimplementedError();
  }

  @override
  bool needsConvertion(Node target, Node node) {
    // TODO: implement needsConvertion
    throw UnimplementedError();
  }

  @override
  bool updateNode(Node node, {List<int>? path}) {
    // TODO: implement updateNode
    throw UnimplementedError();
  }

  @override
  bool updateValue(Object value, Node target, {String? id}) {
    // TODO: implement updateValue
    throw UnimplementedError();
  }

  @visibleForTesting
  String printLines({Node? original, Node? now}) {
    int index = 1;
    if (root.isEmpty) return "1. ~\n";
    final StringBuffer buffer = StringBuffer();

    void writeSubNodes(Node node, Limiter limiter) {
      if (limiter.shouldAvoidTraverseInto(node)) {
        final NodeExtractor? extractor = getExtractor(node.type);
        final String line = extractor!
            .formatObjectToStr(
                extractor.getValueFromNode(node, needsTraverse: false))
            .join("")
            .replaceAll('\n', '\\n');
        buffer.writeln("$index. $line");
        index++;
        return;
      } else if (node.isEmpty) {
        buffer.writeln("$index. ¶");
        index++;
        return;
      }

      for (final Node subNode in node.children) {
        writeSubNodes(subNode, limiter);
      }
    }

    for (final Node rootNode in root.children) {
      final Limiter limiter = getLimiter(rootNode.type)!;
      writeSubNodes(rootNode, limiter);
    }

    return buffer.toString();
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
