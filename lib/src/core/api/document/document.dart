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

  bool addNode(Node node, {List<int>? paths}) {
    return _tree.addNode(node, paths: paths);
  }

  bool deleteNodesBySelection(TextSelection selection) {
    // TODO: implement deleteNodesBySelection
    throw UnimplementedError();
  }

  bool deleteText(TextSelection selection) {
    // TODO: implement deleteText
    throw UnimplementedError();
  }

  Node? getSelectedNode(TextSelection selection) {
    // TODO: implement getSelectedNode
    throw UnimplementedError();
  }

  String getTextAtSelection(TextSelection selection) {
    // TODO: implement getTextAtSelection
    throw UnimplementedError();
  }

  bool insertNode(Node node, {List<int> path = const <int>[]}) {
    // TODO: implement insertNode
    throw UnimplementedError();
  }

  bool insertNodeAtRoot(Node node, {int path = -1}) {
    // TODO: implement insertNodeAtRoot
    throw UnimplementedError();
  }

  bool insertText(TextSelection selection) {
    // TODO: implement insertText
    throw UnimplementedError();
  }

  bool insertTextAtNode(Node target, String text, List<int> path) {
    // TODO: implement insertTextAtNode
    throw UnimplementedError();
  }

  bool moveNodeTo(Node node, int path, {bool internally = true}) {
    // TODO: implement moveNodeTo
    throw UnimplementedError();
  }

  bool moveNodes(List<Node> nodes, int to, {bool after = false}) {
    // TODO: implement moveNodes
    throw UnimplementedError();
  }

  bool needsConvertion(Node target, Node node) {
    // TODO: implement needsConvertion
    throw UnimplementedError();
  }

  Node? query(String id,
      {bool deep = true, String? targetId, bool strict = true}) {
    // TODO: implement query
    throw UnimplementedError();
  }

  NodeCursorPosLocation? queryOffset(int cursorPos, {bool strict = false}) {
    // TODO: implement queryOffset
    throw UnimplementedError();
  }

  Node? queryPath(List<int> path) {
    // TODO: implement queryPath
    throw UnimplementedError();
  }

  List<Node> querySelectedNodes(NodeSelection selection) {
    // TODO: implement querySelectedNodes
    throw UnimplementedError();
  }

  List<NodeValueLocation> queryValue(Object value) {
    // TODO: implement queryValue
    throw UnimplementedError();
  }

  bool updateNode(Node node, {List<int>? path}) {
    // TODO: implement updateNode
    throw UnimplementedError();
  }

  bool updateValue(Object value, Node target, {String? id}) {
    // TODO: implement updateValue
    throw UnimplementedError();
  }
}
