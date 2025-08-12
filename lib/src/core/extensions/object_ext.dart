import 'package:flutter_quill_delta_easy_parser/flutter_quill_delta_easy_parser.dart';

extension CastExt on Object {
  T cast<T>() => this as T;
  T? castOrNull<T>() => this is T ? this as T : null;
  List<TextFragment> castToFragments() => cast<List<TextFragment>>();
  String castString() => cast<String>();
}

extension EasyLength on Object {
  int get length => this is String
      ? castString().length
      : 1;
}

extension StringSubExt on String {
  String left(int offset) => substring(0, offset);
  String right(int offset) => substring(offset);
}
