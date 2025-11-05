import 'dart:ui';

import 'package:easy_rich_editor/easy_rich_editor.dart';

///
class NodePosition {
  /// The node depth path of the node at the cursor position
  final NodeDepthPath path;

  /// Relative [posOffset] into the path
  ///
  /// You can get the correct [offset] position
  /// (into the [EasyDocument]) making a [query].
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
  final int posOffset;

  /// The [id] of the node at this position
  final String id;

  final TextAffinity? affinity;

  NodePosition.invalid()
      : path = invalidaPath,
        posOffset = -1,
        id = "",
        affinity = null;

  NodePosition({
    required this.path,
    required this.posOffset,
    required this.id,
    this.affinity,
  });

  NodePosition copyWith({
    NodeDepthPath? path,
    TextAffinity? affinity,
    int? posOffset,
    String? id,
    Node? node,
  }) {
    return NodePosition(
      path: path ?? this.path,
      id: id ?? this.id,
      affinity: affinity ?? this.affinity,
      posOffset: posOffset ?? this.posOffset,
    );
  }

  bool operator >(NodePosition other) {
    return posOffset > other.posOffset;
  }

  bool operator >=(NodePosition other) {
    return posOffset >= other.posOffset;
  }

  bool operator <(NodePosition other) {
    return posOffset < other.posOffset;
  }

  bool operator <=(NodePosition other) {
    return posOffset <= other.posOffset;
  }

  bool equals(covariant NodePosition other, {bool checkPositions = false}) {
    if (checkPositions) {
      return posOffset == other.posOffset &&
          path == other.path &&
          affinity == other.affinity;
    }
    return this == other && id == other.id;
  }

  @override
  bool operator ==(covariant NodePosition other) {
    return posOffset == other.posOffset &&
        path == other.path &&
        affinity == other.affinity &&
        id == other.id;
  }

  @override
  int get hashCode => Object.hash(
        path,
        posOffset,
        affinity,
        id,
      );
}
