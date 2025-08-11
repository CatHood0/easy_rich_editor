import 'package:flutter/material.dart';

import '../../../easy_rich_editor.dart';

// NOTE: This code was took from AppFlowy repository
// I'll take care about it when required
// to change to the implementation that we need
mixin SelectableMixin on State<StatefulWidget> {
  /// Returns the [Rect] representing the block selection in current widget.
  ///
  /// Normally, the rect should not include the action menu area.
  Rect getBlockRect();

  /// Returns the [NodeSelection] surrounded by start and end
  ///   in current widget.
  ///
  /// [start] and [end] are the offsets under the global coordinate system.
  ///
  NodeSelection getSelectionInRange(Offset start, Offset end);

  /// Returns a [List] of the [Rect] area within selection
  ///   in current widget.
  ///
  /// The return result must be a [List] of the [Rect]
  ///   under the local coordinate system.
  List<Rect> getRectsInSelection(
    NodeSelection selection, {
    bool shiftWithBaseOffset = false,
  });

  /// Returns [NodePosition] for the offset in current widget.
  ///
  /// [start] is the offset of the global coordination system.
  NodePosition getPositionInOffset(Offset start);

  /// Returns [Rect] for the position in current widget.
  ///
  /// The return result must be an offset of the local coordinate system.
  Rect? getCursorRectInPosition(
    NodePosition position, {
    bool shiftWithBaseOffset = false,
  }) {
    return null;
  }

  /// Return global offset from local offset.
  Offset localToGlobal(
    Offset offset, {
    bool shiftWithBaseOffset = false,
  });

  NodePosition start();
  NodePosition end();

  /// For [TextNode] only.
  ///
  /// Only the widget rendered by [TextNode] need to implement the detail,
  ///   and the rest can return null.
  TextSelection? getTextSelectionInSelection(NodeSelection selection) => null;

  /// For [TextNode] only.
  ///
  /// Only the widget rendered by [TextNode] need to implement the detail,
  ///   and the rest can return null.
  NodeSelection? getWordBoundaryInOffset(Offset start) => null;

  /// For [TextNode] only.
  ///
  /// Only the widget rendered by [TextNode] need to implement the detail,
  ///   and the rest can return null.
  NodeSelection? getWordBoundaryInPosition(NodePosition position) => null;

  bool get shouldCursorBlink => true;

  CursorStyle get cursorStyle => CursorStyle.verticalLine;

  Rect transformRectToGlobal(
    Rect r, {
    bool shiftWithBaseOffset = false,
  }) {
    final topLeft = localToGlobal(
      r.topLeft,
      shiftWithBaseOffset: shiftWithBaseOffset,
    );
    return Rect.fromLTWH(topLeft.dx, topLeft.dy, r.width, r.height);
  }

  TextDirection textDirection() => TextDirection.ltr;
}

enum CursorStyle {
  verticalLine,
  blockLine,
}
