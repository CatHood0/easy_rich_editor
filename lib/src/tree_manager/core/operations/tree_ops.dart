import 'package:flutter/material.dart' show TextRange, TextSelection;

import '../../../../easy_rich_editor.dart';

abstract interface class TreeOperations {
  List<NodeValueLocation> queryValue(Object value);
  Node? queryPath(List<int> path);

  Node? query(
    String id, {
    bool deep = true,
    String? targetId,
    bool strict = true,
  });

  bool insertNode(Node node, {List<int> path = const <int>[]});
  bool addNode(Node node, {List<int>? paths});
  bool insertNodeAtRoot(Node node, {int path = -1});
  bool insertTextAtNode(Node target, String text, List<int> path);
  bool moveNodeTo(Node node, int path, {bool internally = true});
  bool moveNodes(List<Node> nodes, int to, {bool after = false});

  bool needsConvertion(Node target, Node node);

  bool insertText(TextSelection selection);

  bool updateNode(Node node, {List<int>? path});

  bool updateValue(Object value, Node target, {String? id});

  bool deleteNodesBySelection(TextSelection selection);

  bool deleteText(TextSelection selection);

  // ========== SELECTION ============

  int computeGlobalStartPosition(Node node);
  int computeGlobalEndPosition(Node node);
  TextRange computeRangePosition(Node node);
  TextRange computeLocalRangePosition(Node node);
  String getTextAtSelection(TextSelection selection);
  List<Node> getSelectedNodes(TextSelection selection);
  Node? getSelectedNode(TextSelection selection);
}
