import 'package:easy_rich_editor/easy_rich_editor.dart';
import 'package:easy_rich_editor/src/core/extensions/object_ext.dart';
import 'package:flutter_quill_delta_easy_parser/blocks/text_fragment.dart';

extension NodeExt on Node {
  bool get hasText =>
      value != null &&
      value is List<TextFragment> &&
      value!.cast<List<TextFragment>>().isNotEmpty;

  bool get isBlankText =>
      value != null &&
      value is List<TextFragment> &&
      value!.cast<List<TextFragment>>().isNotEmpty;

  bool get hasEmbed =>
      value != null &&
      value is List<Map<String, dynamic>> &&
      value!.cast<List<Map<String, dynamic>>>().isNotEmpty;

  bool get isBlank => value != null;
}
