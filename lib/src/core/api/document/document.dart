import 'package:easy_rich_editor/src/tree_manager/tree.dart';
import 'package:flutter/material.dart';
import '../../../../easy_rich_editor.dart';

class Document {
  final Tree _tree;

  Document(Node root) : _tree = Tree(root);

  Document.json(
    Map<String, dynamic> json,
  ) : _tree = Tree.json(json);

  Document.fromList(
    List<Node> children,
  ) : _tree = Tree.root(nodes: children);

  @override
  bool addNode(Node node, {List<int>? paths}) {
    return _tree.addNode(node, paths: paths);
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
  Node? query(String id,
      {bool deep = true, String? targetId, bool strict = true}) {
    // TODO: implement query
    throw UnimplementedError();
  }

  @override
  NodeCursorPosLocation? queryOffset(int cursorPos, {bool strict = false}) {
    // TODO: implement queryOffset
    throw UnimplementedError();
  }

  @override
  Node? queryPath(List<int> path) {
    // TODO: implement queryPath
    throw UnimplementedError();
  }

  @override
  List<Node> querySelectedNodes(NodeSelection selection) {
    // TODO: implement querySelectedNodes
    throw UnimplementedError();
  }

  @override
  List<NodeValueLocation> queryValue(Object value) {
    // TODO: implement queryValue
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
}
