import 'package:easy_rich_editor/src/core/extensions/object_ext.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_quill_delta_easy_parser/flutter_quill_delta_easy_parser.dart';

import '../../../../easy_rich_editor.dart';

extension TextFragmentExt on TextFragment {
  /// Converts the operation to its plain text representation.
  String toPlain({String Function(Object embedData)? embedBuilder}) {
    return data is String
        ? '$data'
        : embedBuilder?.call(data) ?? Node.kObjectReplacementCharacter;
  }

  int get length => isText ? data.castString().length : 1;

  String text(
          {String ifNot = Node.kObjectReplacementCharacter,
          String Function(Object d)? ifNotBuilder}) =>
      isText ? getTextValue() : ifNotBuilder?.call(data) ?? ifNot;

  bool get hasAttributes => attributes != null && attributes!.isNotEmpty;
  bool get hasNoAttributes => !hasAttributes;

  bool hasSameAttributes(Map<String, dynamic>? attrs) =>
      mapEquals<String, dynamic>(attributes, attrs);

  /// Returns `true` if this node contains character at specified [offset] in
  /// the document.
  bool containsOffset(int offset) {
    return offset >= 0 && offset <= length;
  }
}
