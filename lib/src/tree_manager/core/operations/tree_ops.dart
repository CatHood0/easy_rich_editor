import 'package:flutter/material.dart' show TextSelection;
import 'package:meta/meta.dart';

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

  /// Queries the child [Node] at [offset] in [Tree].
  ///
  /// The result may contain the found node or `null` if no node is found
  /// at specified offset.
  ///
  /// [strict] is set to determine if we want to traverse in the Tree
  /// until found the `Node` with the exact `TextFragment` position
  NodeCursorPosLocation? queryOffset(
    int cursorPos, {
    bool includeLastNode = false,
    @experimental bool strict = false,
  });

  /// Queries the children [Node] that are wrapped by the [selection] in [Tree].
  ///
  /// The result may contain the found node or `null` if no node is found
  /// at specified [selection].
  List<Node> querySelectedNodes(TextSelection selection);

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

  String getTextAtSelection(TextSelection selection);
  Node? getSelectedNode(TextSelection selection);
}
