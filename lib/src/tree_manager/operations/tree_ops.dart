import 'package:flutter/material.dart' show TextRange, TextSelection;
import 'package:easy_rich_editor/internal.dart';

abstract interface class TreeOperations {
  String insertNodeAt(Node node, {List<int>? path});
  bool moveNodes(List<Node> nodes, int to);

  Node? query(String rs, {Map<String, dynamic> args = const {}});
  List<Node> queryList(String rs, {Map<String, dynamic> args = const {}});
  List<Node> queryNodes(List<String> ids, {Map<String, dynamic> args = const {}});

  int computeGlobalStartPosition(Node node);
  int computeGlobalEndPosition(Node node);
  TextRange computeRangePosition(Node node);
  TextRange computeLocalRangePosition(Node node);
  String getTextAtSelection(TextSelection selection);
  List<Node> getSelectedNodes(TextSelection selection);
  Node? getSelectedNode(TextSelection selection);
  String? insertNode(Node node, int offset);
  String? addNode(Node node);
  bool insertNodeAtPath(Node node, List<int> path);
  bool insertTextAtNode(Node target, String text, List<int> path);
  bool moveNodeTo(Node node, int path, {bool internally = true});
  bool canInsertInto(Node target, Node node);
  bool needsConvertion(Node target, Node node);
  bool convertToType(Node ownerTarget, Node node);

  bool insertText(TextSelection selection);

  bool updateNode(Node node);

  bool deleteNodesBySelection(TextSelection selection);

  bool updateText(String text, Node target, {String? id});

  bool deleteText(TextSelection selection);
}
