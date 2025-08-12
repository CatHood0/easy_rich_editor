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

  String text(
          {String ifNot = Node.kObjectReplacementCharacter,
          String Function(Object d)? ifNotBuilder}) =>
      this is String ? castString() : ifNotBuilder?.call(this) ?? ifNot;
}

extension StringSubExt on String {
  String left(int offset) => substring(0, offset);
  String right(int offset) => substring(offset);
}

extension StringNullable on String? {
  String get orEmpty => this == null ? "" : this!;
}
