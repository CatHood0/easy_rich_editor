import 'package:easy_rich_editor/src/core/api/location/node_text_location.dart';
import 'package:flutter/material.dart' show TextRange, TextSelection;
import 'package:easy_rich_editor/internal.dart';

abstract interface class TreeOperations {
  List<NodeTextLocation> queryValue(Object value);
  Node? queryPath(List<int> path);

  List<Node> queryNodes(
    List<String> ids, {
    bool deep = true,
    String? targetId,
  });

  Node? query(
    String id, {
    bool deep = true,
    String? targetId,
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
