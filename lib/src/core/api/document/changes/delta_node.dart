/// Represents the granular change do it to a particular [Node]
class DeltaNode {
  /// Represents where ends the change into the node
  final int end;

  /// Represents where starts the change into the node
  final int start;
  final int newLength;
  final int oldLength;
  final Object? inserted;

  /// Determines if we will delete all the nodes
  /// in the range of the [start] and [end]
  final bool replaceOffsets;

  DeltaNode({
    required this.oldLength,
    required this.newLength,
    required this.inserted,
    required this.start,
    required this.end,
    required this.replaceOffsets,
  });

  /// Returns a Boolean indicating whether the selection is backward.
  bool get isBackward => start < end;

  /// Returns a Boolean indicating whether the selection is fordward.
  bool get isForward => start > end;

  /// Returns a Boolean indicating whether the selection is forward/normalized.
  bool get isNormalized => start > end;

  /// Returns a Boolean indicating whether the selection start and ends in the same place.
  bool get isCollapsed => start == end;

  bool get isDeletion => !isInsertion && replaceOffsets;

  bool get isReplace => isInsertion && replaceOffsets;

  bool isSelectingEntireRanges(int start, int end, {bool strict = true}) {
    return this.start == start && this.end == end ||
        !strict && isWrappingSelection(start, end);
  }

  bool isWrappingSelection(int start, int end) {
    return this.start <= start && this.end >= end;
  }

  bool get isInsertion => inserted != null;

  /// Returns a normalized selection that direction is forward.
  DeltaNode get normalized => isBackward
      ? this
      : DeltaNode(
          start: end,
          end: start,
          inserted: inserted,
          oldLength: oldLength,
          newLength: newLength,
          replaceOffsets: replaceOffsets,
        );

  DeltaNode transformPoints(int newStart, int newEnd) {
    return DeltaNode(
      start: newStart,
      end: newEnd,
      inserted: inserted,
      oldLength: oldLength,
      newLength: newLength,
      replaceOffsets: replaceOffsets,
    );
  }

  DeltaNode transformRanges(int point, {bool decrease = true}) {
    return DeltaNode(
      start: decrease ? start - point : start + point,
      end: decrease ? end - point : end + point,
      inserted: inserted,
      oldLength: oldLength,
      newLength: newLength,
      replaceOffsets: replaceOffsets,
    );
  }
}

class DeltaChangeResult {
  final bool removed;
  final bool executed;
  final bool inserted;
  final bool removedEntireNode;
  final int newValidCursorPosition;

  DeltaChangeResult({
    this.removed = false,
    this.executed = true,
    this.inserted = false,
    this.removedEntireNode = false,
    this.newValidCursorPosition = -1,
  });

  DeltaChangeResult.noExecution()
      : removed = false,
        executed = false,
        inserted = false,
        newValidCursorPosition = -1,
        removedEntireNode = false;
}
