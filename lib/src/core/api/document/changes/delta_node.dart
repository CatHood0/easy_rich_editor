import 'package:easy_attribution_text/easy_text.dart';

enum DeltaType {
  insert,
  replace,
  delete,
  format,
}

/// Represents the granular change do it to a particular [Node]
class DeltaNode {
  /// Represents where ends the change into the node
  final int end;

  /// Represents where starts the change into the node
  final int start;
  final int newLength;
  final int oldLength;
  final Object? inserted;
  final EasyAttributeStyles styles;

  /// Whether the [styles] must be applied to the inserted object
  final bool inlineStyles;

  /// The [type] of change that this [Delta] is
  final DeltaType type;

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
    required this.styles,
    required this.inlineStyles,
    required this.type,
  });

  DeltaNode.invalid()
      : start = -1,
        end = -1,
        newLength = -1,
        oldLength = -1,
        inserted = null,
        replaceOffsets = false,
        styles = EasyAttributeStyles.empty(),
        type = DeltaType.insert,
        inlineStyles = false;

  DeltaNode.format({
    required int len,
    required this.start,
    required this.styles,
    required this.inlineStyles,
  })  : end = start + len,
        oldLength = 0,
        newLength = 0,
        replaceOffsets = false,
        type = DeltaType.format,
        inserted = null;

  DeltaNode.insert({
    required Object insert,
    required this.start,
    required this.styles,
  })  : end = start,
        oldLength = 0,
        newLength = 0,
        inlineStyles = true,
        replaceOffsets = false,
        type = DeltaType.insert,
        inserted = insert;

  DeltaNode.replace({
    required this.inserted,
    required this.start,
    required this.end,
  })  : oldLength = 0,
        newLength = 0,
        inlineStyles = false,
        replaceOffsets = false,
        type = DeltaType.replace,
        styles = EasyAttributeStyles.empty();

  DeltaNode.delete({
    required this.start,
    required this.end,
  })  : oldLength = 0,
        newLength = 0,
        inlineStyles = false,
        replaceOffsets = false,
        type = DeltaType.delete,
        inserted = null,
        styles = EasyAttributeStyles.empty();

  /// Whether this [DeltaNode] is a format change
  bool get isFormat => type == DeltaType.format;

  /// Whether this [DeltaNode] is a deletion change
  bool get isDeletion =>
      !isInsertion && replaceOffsets || type == DeltaType.delete;

  /// Whether this [DeltaNode] is a replace change
  bool get isReplace => isInsertion && type == DeltaType.replace;

  /// Whether this [DeltaNode] is an insert change
  bool get isInsertion => type == DeltaType.insert;

  /// Returns a Boolean indicating whether the selection is backward.
  bool get isBackward => start < end;

  /// Returns a Boolean indicating whether the selection is fordward.
  bool get isForward => start > end;

  /// Returns a Boolean indicating whether the selection is forward/normalized.
  bool get isNormalized => start > end;

  /// Returns a Boolean indicating whether the selection start and ends in the same place.
  bool get isCollapsed => start == end;

  bool isSelectingEntireRanges(int start, int end, {bool strict = true}) {
    return this.start == start && this.end == end ||
        !strict && isWrappingSelection(start, end);
  }

  bool isWrappingSelection(int start, int end) {
    return this.start <= start && this.end >= end;
  }

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
          inlineStyles: inlineStyles,
          styles: styles,
          type: type,
        );

  DeltaNode transformPoints(int newStart, int newEnd) {
    return DeltaNode(
      start: newStart,
      end: newEnd,
      inserted: inserted,
      oldLength: oldLength,
      newLength: newLength,
      replaceOffsets: replaceOffsets,
      styles: styles,
      inlineStyles: inlineStyles,
      type: type,
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
      styles: styles,
      inlineStyles: inlineStyles,
      type: type,
    );
  }
}

class DeltaChangeResult {
  final String nodeId;
  final bool removed;
  final bool executed;
  final bool inserted;
  final bool removedEntireNode;
  final EasyAttributeStyles? styles;
  final int newValidCursorPosition;

  DeltaChangeResult({
    required this.nodeId,
    this.styles,
    this.removed = false,
    this.executed = true,
    this.inserted = false,
    this.removedEntireNode = false,
    this.newValidCursorPosition = -1,
  });

  DeltaChangeResult.noExecution()
      : removed = false,
        styles = null,
        nodeId = '',
        executed = false,
        inserted = false,
        newValidCursorPosition = -1,
        removedEntireNode = false;
}
