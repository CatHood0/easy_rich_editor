import 'package:flutter/services.dart';

extension RunesPositioning on String {
  /// Returns the position of the previous grapheme cluster boundary.
  int prevRunePosition(int pos) {
    if (pos == 0) return -1;
    return CharacterBoundary(this).getLeadingTextBoundaryAt(pos - 1) ?? 0;
  }

  /// Returns the position of the next grapheme cluster boundary.
  int nextRunePosition(int pos) {
    if (pos >= length - 1) return length;
    return CharacterBoundary(this).getTrailingTextBoundaryAt(pos) ?? length;
  }
}
