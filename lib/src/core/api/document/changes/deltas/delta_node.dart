import 'package:easy_attribution_text/easy_text.dart';
import 'package:easy_rich_editor/easy_rich_editor.dart';

enum DeltaType {
  insert,
  replace,
  delete,
  format,
  manual,
}

/// Represents the granular change do it to a particular [Node]
class DeltaNode {
  final Object? inserted;
  final EasyAttributeStyles styles;
  final NodeSelection selection;

  /// Whether the [styles] must be applied to the inserted object
  final bool inlineStyles;

  /// The [type] of change that this [Delta] is
  final DeltaType type;

  /// Determines if we will delete all the nodes
  /// in the range of the [start] and [end]
  final bool replaceOffsets;

  DeltaNode({
    required this.inserted,
    required this.replaceOffsets,
    required this.selection,
    required this.styles,
    required this.type,
    this.inlineStyles = true,
  });

  DeltaNode.invalid()
      : selection = NodeSelection.invalid(),
        inserted = null,
        replaceOffsets = false,
        styles = EasyAttributeStyles.empty(),
        type = DeltaType.manual,
        inlineStyles = false;

  DeltaNode.format({
    required this.styles,
    required this.inlineStyles,
    required this.selection,
  })  : replaceOffsets = false,
        type = DeltaType.format,
        inserted = null;

  DeltaNode.insert({
    required Object insert,
    required this.selection,
    required this.styles,
  })  : inlineStyles = true,
        replaceOffsets = false,
        type = DeltaType.insert,
        inserted = insert;

  DeltaNode.replace({
    required Object data,
    required this.selection,
    EasyAttributeStyles? styles,
    this.inlineStyles = true,
  })  : inserted = data,
        replaceOffsets = false,
        type = DeltaType.replace,
        styles = styles ?? EasyAttributeStyles.empty();

  DeltaNode.delete({
    required this.selection,
  })  : inlineStyles = false,
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
  bool get isInsertion => type == DeltaType.insert || inserted != null;

  /// Returns the [start] offset change in characters of this [DeltaNode]
  int get start => selection.startIndex;

  /// Returns the [end] offset change in characters of this [DeltaNode]
  int get end => selection.endIndex;

  /// Returns a Boolean indicating whether the selection is backward.
  bool get isBackward => selection.isBackward;

  /// Returns a Boolean indicating whether the selection is fordward.
  bool get isForward => selection.isForward;

  /// Returns a Boolean indicating whether the selection is forward/normalized.
  bool get isNormalized => selection.isNormalized;

  /// Returns a Boolean indicating whether the selection start and ends in the same place.
  ///
  /// Tipically is collapsed during when [type] is [insertion]
  bool get isCollapsed => selection.isCollapsed;

  bool isSelectingEntireRanges(int start, int end, {bool strict = true}) {
    return this.start == start && this.end == end ||
        !strict && isWrappingNodeSelection(start, end);
  }

  bool isWrappingNodeSelection(int start, int end) {
    return this.start <= start && this.end >= end;
  }

  /// Returns a normalized selection that direction is forward.
  DeltaNode get normalized => isBackward
      ? this
      : DeltaNode(
          selection: selection.normalized,
          inserted: inserted,
          replaceOffsets: replaceOffsets,
          inlineStyles: inlineStyles,
          styles: styles,
          type: type,
        );

  DeltaNode transformPoints(int newStart, int newEnd) {
    return DeltaNode(
      inserted: inserted,
      selection: selection.copyWith(
        start: selection.start.copyWith(posOffset: newStart),
        end: selection.end.copyWith(posOffset: newStart),
      ),
      replaceOffsets: replaceOffsets,
      styles: styles,
      inlineStyles: inlineStyles,
      type: type,
    );
  }

  DeltaNode transformRanges(int point, {bool decrease = true}) {
    return transformPoints(
      decrease ? start - point : start + point,
      decrease ? end - point : end + point,
    );
  }

  @override
  String toString() {
    return switch (type) {
      DeltaType.insert => 'DeltaNode(data: $inserted, '
          'stylesAreInline: $styles '
          'selection: $selection, '
          'styles: $styles)',
      DeltaType.replace => 'DeltaNode('
          'data: $inserted, '
          'selection: $selection, '
          'stylesAreInline: $styles '
          'styles: $styles)',
      DeltaType.delete => 'DeltaNode(selection: $selection)',
      DeltaType.format => 'DeltaNode('
          'selection: $selection, '
          'stylesAreInline: $styles '
          'styles: $styles)',
      _ => 'Delta(data: $inserted '
          'selection: $selection, '
          'type: $type '
          'styles: $styles '
          'stylesAreInline: $inlineStyles '
          'replaceOffsets: $replaceOffsets)',
    };
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
    this.inserted = false,
    this.removedEntireNode = false,
    this.newValidCursorPosition = -1,
    this.executed = true,
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
