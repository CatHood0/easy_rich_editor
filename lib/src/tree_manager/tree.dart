import 'package:easy_rich_editor/src/core/api/location/node_text_location.dart';
import 'package:easy_rich_editor/src/core/limiters/embed_limiter.dart';
import 'package:easy_rich_editor/src/tree_manager/core/indexer/tree_indexer.dart';
import 'package:easy_rich_editor/src/tree_manager/core/cache_invalidator/tree_cache_invalidator.dart';
import 'package:easy_rich_editor/src/utils/background_isolate_runner/isolate_runner.dart';
import 'package:flutter/cupertino.dart';
import 'package:easy_rich_editor/easy_rich_editor.dart';
import 'package:meta/meta.dart';

import '../../internal.dart';

@internal
class Tree extends ValueNotifier<Node> implements TreeOperations {
  Tree(this.root) : super(root) {
    _isolateTreeIndexer.run(
      TreeIndexerPayload(root: root),
      callback: (TreeIndexerResult result) {
        _indexedTree.addAll(result.indexes);
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

  late final Map<String, Node> _indexedTree = <String, Node>{};

  @visibleForTesting
  Map<String, Node> get indexTree => <String, Node>{..._indexedTree};

  late final _isolateTreeIndexer =
      IsolateRunner<TreeIndexerPayload, TreeIndexerResult>(
    'tree indexer',
    _indexTree,
    restartIfAlreadyIsRunning: true,
  );
  late final _isolateCacheInvalidator =
      IsolateRunner<TreeCacheInvalidatorPayload, TreeCacheInvalidatorResult>(
    'cache invalidator',
    _invalidateCachedPaths,
    restartIfAlreadyIsRunning: true,
  );

  final Node root;

  /// A simple register with all the limiters.
  ///
  /// Typically, this is used when we need to traverse
  /// to get text info, and we need the specifications
  /// of how works that node type
  static final Map<String, Limiter> _limiters = {
    EmbedKeys.key: EmbedLimiter.instance(),
    ParagraphKeys.key: ParagraphLimiter.instance(),
  };

  /// A simple register with all the extractors.
  ///
  /// Typically, this is used when we need to get values
  /// from a Node, since every Node has a different way to save
  /// its content, we need implement it's own extractor
  static final Map<String, NodeExtractor> _extractors = {
    ParagraphKeys.key: ParagraphNodeExtractor.instance,
    EmbedKeys.key: EmbedNodeExtractor.instance,
  };

  static Limiter? getLimiter(String key) {
    return _limiters[key];
  }

  static NodeExtractor? getExtractor(String key) {
    return _extractors[key];
  }

  @override
  Node? query(String id, {Map<String, dynamic> args = const {}}) {
    Node? node;
    final bool deep = args['traverse'] as bool? ?? false;

    return node;
  }

  @override
  List<Node> queryNodes(List<String> ids,
      {Map<String, dynamic> args = const {}}) {
    throw UnimplementedError();
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
  List<NodeTextLocation> queryValue(Object value,
      {Map<String, dynamic> args = const {}}) {
    throw UnimplementedError();
  }

  @override
  bool addNode(Node node, {List<int>? paths}) {
    // TODO: implement addNode
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
  static TreeIndexerResult _indexTree(TreeIndexerPayload payload) {
    final Map<String, Node> nodes = {};
    for (Node node in payload.root.children) {
      nodes[node.id] = node;
    }
    return TreeIndexerResult(nodes);
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
}
