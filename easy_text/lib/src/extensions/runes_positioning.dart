import 'package:flutter/services.dart';

//FIXME: should we remove this? since we implement character package
// this is probably don't needed
extension RunesPositioning on String {
  /// This method will return the position of the previous rune.
  ///
  /// Since the encoding of the [String] in Dart is UTF-16.
  /// If you want to find the previous character of a position,
  /// you can't just use the `position - 1` simply.
  ///
  /// This method can help you to compute the position of the previous character.
  int prevRunePosition(int pos) {
    if (pos == 0) {
      return pos - 1;
    }
    final int? index =
        CharacterBoundary(this).getLeadingTextBoundaryAt(pos - 1);
    return index ?? 0;
  }

  /// This method will return the position of the next rune.
  ///
  /// Since the encoding of the [String] in Dart is UTF-16.
  /// If you want to find the next character of a position,
  /// you can't just use the `position + 1` simply.
  ///
  /// This method can help you to compute the position of the next character.
  int nextRunePosition(int pos) {
    if (pos >= length - 1) {
      return length;
    }
    final int? index = CharacterBoundary(this).getTrailingTextBoundaryAt(
      pos,
    );
    return index ?? length;
  }
}
