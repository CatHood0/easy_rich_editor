import 'package:easy_rich_editor/src/core/api/document/path/path.dart';
import 'package:flutter_quill_delta_easy_parser/flutter_quill_delta_easy_parser.dart';

import '../../../easy_rich_editor.dart';

extension CastExt on Object {
  T cast<T>() => this as T;
  T? castOrNull<T>() => this is T ? this as T : null;
  List<TextFragment> castToFragments() => cast<List<TextFragment>>();
  String castString() => cast<String>();
}

extension DynamicCast on dynamic {
  T cast<T>() => this as T;
  T? castOrNull<T>() => this is T ? this as T : null;
  List<TextFragment> castToFragments() => cast<List<TextFragment>>();
  String castString() => cast<String>();
}

extension EasyObjects on Object {
  int get length => this is String ? castString().length : 1;

  String text({
    String ifNot = Node.kObjectReplacementCharacter,
    String Function(Object d)? ifNotBuilder,
  }) =>
      this is String ? castString() : ifNotBuilder?.call(this) ?? ifNot;
}

extension NonNegativeInt on int {
  int get nonNegative => this < 0 ? 0 : this;
}

extension IntList on int {
  List<int> until(int end, {bool backward = false}) {
    List<int> nums = <int>[this];
    if (this == end) return nums;
    if (backward) {
      for (int i = prev.nonNegative; i > 0; i--) {
        nums.add(i);
      }
      return <int>[...nums.reversed];
    }
    for (int i = next; i < end; i++) {
      nums.add(i);
    }
    return nums;
  }

  int limit(int max) {
    return this > max ? max : this;
  }

  int or(int another, {int min = -1}) {
    return this <= min ? another : this;
  }
}

extension StringSubExt on String {
  String left(int offset) => substring(0, offset);
  String right(int offset) => substring(offset);
  String? orNull() => isEmpty ? null : this;
}

extension StringNullable on String? {
  String get orEmpty => this == null ? "" : this!;
}
