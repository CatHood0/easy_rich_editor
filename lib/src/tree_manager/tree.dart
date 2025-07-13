import 'package:easy_rich_editor/src/core/limiters/embed_limiter.dart';
import 'package:easy_rich_editor/src/tree_manager/core/indexer/tree_indexer.dart';
import 'package:easy_rich_editor/src/tree_manager/core/cache_invalidator/tree_cache_invalidator.dart';
import 'package:easy_rich_editor/src/utils/background_isolate_runner/isolate_runner.dart';
import 'package:flutter/cupertino.dart';
import 'package:easy_rich_editor/easy_rich_editor.dart';
import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';

import '../../internal.dart';

@internal
class Tree extends ValueNotifier<Node> implements TreeOperations {
  static final String id = 'Tree';
  Tree(this.root) : super(root) {
    IsolateTreeIndexer.getSafeIsolate(
      id: id,
      forceReturningFromIdAlways: true,
    ).run(
      TreeIndexerPayload(
        root: root,
        loadAfter: 0,
        newValueAfter: 1,
        curIndexTree: <String, int>{},
      ),
      callback: (TreeIndexerResult result) {
        _indexedTree = result.indexes;
      },
    );
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

  /// A indexed version of the tree and must be updated
  /// always, never can lost a update, insert or delete operation
  late Map<String, int> _indexedTree = <String, int>{};

  @visibleForTesting
  Map<String, int> get indexTree => <String, int>{..._indexedTree};

  late final _isolateCacheInvalidator =
      IsolateRunner<TreeCacheInvalidatorPayload, TreeCacheInvalidatorResult>(
    'cache invalidator',
    _invalidateCachedPaths,
    restartIfAlreadyIsRunning: true,
  );

  //TODO: build a indexedTree for every node (into the Node class)
  // to cache these and make more fast the queries
  /// The root source of every Node used into the Tree
  final Node root;

  /// updated externally for the editor, to cache the current position
  NodeLocation? lastKnowedLocation;

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

  /// TODO: verify that the key exist
  static Limiter? getLimiter(String key) {
    return _limiters[key];
  }

  static NodeExtractor? getExtractor(String key) {
    return _extractors[key];
  }

  // ignore: unused_element
  void _updateIndexedTreeIfNeeded(Node node) {
    final int? original = _indexedTree[node.id];
    if (original == null) return;

    if (original != node.path) {
      _indexedTree[node.id] = node.path;
    }
  }

  @override
  Node? query(String id, {bool deep = true, String? targetId}) {
    Node? node;

    if (!deep && targetId == null) {
      final int? path = _indexedTree[id];
      if (path == null) {
        return null;
      }
      return root.elementAtOrNull(path);
    }

    // normally the root parent of the node to search
    if (targetId != null) {
      final int? path = _indexedTree[targetId];
      if (path == null) {
        return null;
      }
      Node targetNode = root.elementAtOrNull(path)!;
      node = targetNode.findById(id, deep: deep);
    } else if (deep) {
      node = root.findById(id);
    }

    return node;
  }

  /// Find the Node at the full path passed
  ///
  /// path must be always normalized
  /// (source as first element, and the element as the last one)
  @override
  Node? queryPath(List<int> path) {
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

    int rootIndex = 0;
    Node? rootNode = root.firstChild;
    while (rootNode != null) {
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
      rootNode = rootNode.next;
      rootIndex++;
    }

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
  int computeGlobalEndPosition(Node node) {
    // TODO: implement computeGlobalEndPosition
    throw UnimplementedError();
  }

  @override
  int computeGlobalStartPosition(Node node) {
    // TODO: implement computeGlobalStartPosition
    throw UnimplementedError();
  }

  @override
  TextRange computeLocalRangePosition(Node node) {
    // TODO: implement computeLocalRangePosition
    throw UnimplementedError();
  }

  @override
  TextRange computeRangePosition(Node node) {
    // TODO: implement computeRangePosition
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
  List<Node> getSelectedNodes(TextSelection selection) {
    // TODO: implement getSelectedNodes
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

  @pragma('vm:entry-point')
  static TreeCacheInvalidatorResult _invalidateCachedPaths(
    TreeCacheInvalidatorPayload payload,
  ) {
    return TreeCacheInvalidatorResult(
      true,
      lastUnresolvedPath: -1,
    );
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
