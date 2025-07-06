import 'package:easy_rich_editor/src/core/limiters/embed_limiter.dart';
import 'package:flutter/cupertino.dart';
import 'package:easy_rich_editor/easy_rich_editor.dart';
import 'package:meta/meta.dart';

import '../../internal.dart';

@internal
class Tree extends ValueNotifier<Node> implements TreeOperations {
  Tree(this.node) : super(node);

  factory Tree.root({
    required List<Node> nodes,
  }) {
    return Tree(
      Node.root(
        children: nodes,
      ),
    );
  }

  final Node node;

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
  Node? query(String rs, {Map<String, dynamic> args = const {}}) {
    // TODO: implement query
    throw UnimplementedError();
  }

  @override
  List<Node> queryList(String rs, {Map<String, dynamic> args = const {}}) {
    // TODO: implement queryList
    throw UnimplementedError();
  }

  @override
  List<Node> queryNodes(List<String> ids,
      {Map<String, dynamic> args = const {}}) {
    throw UnimplementedError();
  }

  @override
  String? addNode(Node node) {
    // TODO: implement addNode
    throw UnimplementedError();
  }

  @override
  bool canInsertInto(Node target, Node node) {
    // TODO: implement canInsertInto
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
  bool convertToType(Node ownerTarget, Node node) {
    // TODO: implement convertToType
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
  String? insertNode(Node node, int offset) {
    // TODO: implement insertNode
    throw UnimplementedError();
  }

  @override
  String insertNodeAt(Node node, {List<int>? path}) {
    // TODO: implement insertNodeAt
    throw UnimplementedError();
  }

  @override
  bool insertNodeAtPath(Node node, List<int> path) {
    // TODO: implement insertNodeAtPath
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
  bool moveNodes(List<Node> nodes, int to) {
    // TODO: implement moveNodes
    throw UnimplementedError();
  }

  @override
  bool needsConvertion(Node target, Node node) {
    // TODO: implement needsConvertion
    throw UnimplementedError();
  }

  @override
  bool updateNode(Node node) {
    // TODO: implement updateNode
    throw UnimplementedError();
  }

  @override
  bool updateText(String text, Node target, {String? id}) {
    // TODO: implement updateText
    throw UnimplementedError();
  }
}
