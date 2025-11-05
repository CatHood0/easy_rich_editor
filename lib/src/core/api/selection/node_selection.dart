import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:easy_rich_editor/easy_rich_editor.dart';

class NodeSelection {
  final NodePosition start;
  final NodePosition end;

  final List<Node>? selectedNodes;

  NodeSelection({
    required this.start,
    required this.end,
    this.selectedNodes,
  });

  NodeSelection.invalid()
      : start = NodePosition.invalid(),
        selectedNodes = null,
        end = NodePosition.invalid();

  NodeSelection.collapsed({
    required NodeDepthPath path,
    required int offset,
    required String id,
    Node? node,
  })  : start = NodePosition(
          path: path,
          id: id,
          posOffset: offset,
        ),
        selectedNodes = <Node>[if (node != null) node],
        end = NodePosition(
          path: path,
          id: id,
          posOffset: offset,
        );

  NodeSelection.sameNode({
    required NodeDepthPath path,
    required int startOffset,
    required int endOffset,
    required String id,
    TextAffinity? startAffinity,
    TextAffinity? endAffinity,
    Node? node,
    List<Node>? selectedNodes,
  })  : selectedNodes = selectedNodes ?? <Node>[if (node != null) node],
        start = NodePosition(
          path: path,
          id: id,
          affinity: startAffinity,
          posOffset: startOffset,
        ),
        end = NodePosition(
          path: path,
          id: id,
          affinity: endAffinity,
          posOffset: endOffset,
        );

  /// Returns a Boolean indicating whether the selection's start and end points
  /// are at the same position.
  bool get isCollapsed => start.equals(end, checkPositions: true);

  /// Returns a Boolean indicating whether the selection's start and end points
  /// are at the same path.
  bool get isSingle => start.path.equals(end.path);

  /// Returns a Boolean indicating whether the selection is forward.
  bool get isForward => (start.path > end.path) || (isSingle && start > end);

  /// Returns a Boolean indicating whether the selection is backward.
  bool get isBackward => (start.path < end.path) || (isSingle && start < end);

  /// Returns a Boolean indicating whether the selection is forward/normalized.
  bool get isNormalized => (start.path > end.path) || (isSingle && start > end);

  /// Returns a normalized selection that direction is forward.
  NodeSelection get normalized => isBackward ? this : reversed.copyWith();

  /// Returns a reversed selection.
  NodeSelection get reversed => copyWith(start: end, end: start);

  /// Returns the offset in the starting position under the normalized selection.
  int get startIndex => normalized.start.posOffset;

  bool get shareParent => start.path.isAncestorOf(end.path);

  /// Returns the deep path of the start position.
  NodeDepthPath get startPath => start.path;

  /// Returns the deep path of the end position.
  NodeDepthPath get endPath => end.path;

  /// Returns the offset in the ending position under the normalized selection.
  int get endIndex => end.posOffset;

  int get length => endIndex - startIndex;

  NodeSelection copyWith({
    NodePosition? start,
    NodePosition? end,
    List<Node>? selectedNodes,
  }) {
    return NodeSelection(
      start: start ?? this.start,
      end: end ?? this.end,
      selectedNodes: selectedNodes ?? this.selectedNodes,
    );
  }

  /// Returns the smallest [NodeSelection] that this could expand to in order to
  /// include the given [NodePosition].
  ///
  /// If the given [NodePosition] is already inside of the selection, then
  /// returns `this` without change.
  ///
  /// The returned selection will always be a strict superset of the current
  /// selection. In other words, the selection grows to include the given
  /// [NodePosition].
  ///
  /// If [extentAtIndex] is `true`, then the [NodeSelection.endIndex] will be
  /// placed at the given index regardless of the original order of it and
  /// [NodeSelection.startIndex]. Otherwise, their order will be preserved.
  ///
  /// ## Difference with [extendTo]
  /// In contrast with this method, [extendTo] is a pivot; it holds
  /// [NodeSelection.startIndex] fixed while moving [NodeSelection.endIndex]
  /// to the given [NodePosition]. It doesn't strictly grow the selection and
  /// may collapse it or flip its order.
  NodeSelection expandTo(
    NodePosition nodePosition, [
    bool extentAtIndex = false,
  ]) {
    // If position is already within in the selection, there's nothing to do.
    if (nodePosition >= start && nodePosition <= end) {
      return this;
    }

    if (nodePosition <= start) {
      // Here the position is somewhere before the selection: ..|..[...]....
      if (extentAtIndex) {
        return copyWith(
          start: end,
          end: nodePosition,
        );
      }
      return copyWith(
        start: isNormalized ? nodePosition : start,
        end: isNormalized ? end : nodePosition,
      );
    }
    // Here the position is somewhere after the selection: ....[...]..|..
    if (extentAtIndex) {
      return copyWith(
        start: start,
        end: nodePosition,
      );
    }
    return copyWith(
      start: isNormalized ? start : nodePosition,
      end: isNormalized ? nodePosition : end,
    );
  }

  @override
  bool operator ==(covariant NodeSelection other) {
    if (identical(this, other)) return true;
    return start == other.start &&
        end == other.end &&
        listEquals(
          selectedNodes,
          other.selectedNodes,
        );
  }

  @override
  int get hashCode => Object.hashAllUnordered(<Object?>[
        start,
        end,
        selectedNodes,
      ]);
}
