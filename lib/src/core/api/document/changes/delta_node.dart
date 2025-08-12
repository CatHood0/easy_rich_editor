/// Represents the granular change do it to a particular [Node]
class DeltaNode {
  // Represents where ends the change
  final int end;
  // Represents where starts the change
  //
  // Must be relative
  final int start;
  final int newLength;
  final int oldLength;
  final Object? inserted;

  DeltaNode({
    required this.oldLength,
    required this.newLength,
    required this.inserted,
    required this.start,
    required this.end,
  });

  /// Returns a Boolean indicating whether the selection is backward.
  bool get isBackward => start < end;

  /// Returns a Boolean indicating whether the selection is forward/normalized.
  bool get isNormalized => start > end;

  /// Returns a Boolean indicating whether the selection start and ends in the same place.
  bool get isCollapsed => start == end;

  bool get isDeletion =>
      // when newLength is less than
      // zero, is considered as this Delta
      // is removing something
      newLength < 0 || inserted == null && (newLength - oldLength) < 0;

  bool get isInsertion => inserted != null && inserted is String;

  /// Returns a normalized selection that direction is forward.
  DeltaNode get normalized => isBackward
      ? this
      : DeltaNode(
          oldLength: oldLength,
          newLength: newLength,
          inserted: inserted,
          start: end,
          end: start,
        );
}

class DeltaChangeResult {
  final bool removed;
  final bool executed;
  final bool inserted;
  final bool removedEntireNode;

  DeltaChangeResult({
    this.removed = false,
    this.executed = true,
    this.inserted = false,
    this.removedEntireNode = false,
  });

  DeltaChangeResult.noExecution()
      : removed = false,
        executed = false,
        inserted = false,
        removedEntireNode = false;
}
