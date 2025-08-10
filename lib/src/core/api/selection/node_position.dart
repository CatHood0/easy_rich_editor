import 'dart:ui';

import 'package:easy_rich_editor/easy_rich_editor.dart';
import 'package:easy_rich_editor/src/core/api/document/path/path.dart';

///
class NodePosition {
  /// The node depth path of the node at the cursor position
  final NodeDepthPath path;

  /// Local [position] into the path
  ///
  /// You can get the correct [offset] position
  /// (into the [Document]) making a [query].
  ///
  /// ```dart
  ///  final NodePosition pos = ...;
  ///  final List<int> nodePath = [0, 2];
  ///  final Node? node = Tree.queryPath(paths: nodePath)
  ///  if (node != null) {
  ///    final int offset = node!.globalStart;
  ///    // and, this is the offset that you want
  ///    final int effectiveOffset = offset + pos.position;
  ///  }
  /// ```
  final int position;

  final TextAffinity? affinity;

  /// The node where this position is
  final Node node;

  NodePosition({
    required this.path,
    required this.node,
    required this.position,
    this.affinity,
  });

  NodePosition copyWith({
    NodeDepthPath? path,
    TextAffinity? affinity,
    int? position,
    Node? node,
  }) {
    return NodePosition(
      path: path ?? this.path,
      node: node ?? this.node,
      affinity: affinity ?? this.affinity,
      position: position ?? this.position,
    );
  }

  bool operator >(NodePosition other) {
    return position > other.position;
  }

  bool operator >=(NodePosition other) {
    return position >= other.position;
  }

  bool operator <(NodePosition other) {
    return position < other.position;
  }

  bool operator <=(NodePosition other) {
    return position <= other.position;
  }

  bool equals(covariant NodePosition other, {bool checkPositions = false}) {
    if (checkPositions) {
      return position == other.position &&
          path == other.path &&
          affinity == other.affinity;
    }
    return this == other;
  }

  @override
  bool operator ==(covariant NodePosition other) {
    return position == other.position &&
        path == other.path &&
        node == other.node &&
        affinity == other.affinity;
  }

  @override
  int get hashCode => Object.hashAllUnordered([
        path,
        position,
        affinity,
      ]);
}
