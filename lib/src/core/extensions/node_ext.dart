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

extension NodeEquality on Iterable<Node> {
  bool equals(Iterable<Node> other) {
    if (length != other.length) {
      return false;
    }
    for (var i = 0; i < length; i++) {
      if (!_nodeEquals(elementAt(i), other.elementAt(i))) {
        return false;
      }
    }
    return true;
  }

  bool _nodeEquals<T, U>(T base, U other) =>
      identical(this, other) ||
      base is Node &&
          other is Node &&
          other.type == base.type &&
          other.children.equals(base.children);
}
