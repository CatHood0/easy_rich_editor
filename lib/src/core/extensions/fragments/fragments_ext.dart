import 'package:easy_attribution_text/easy_text.dart';
import 'package:easy_rich_editor/src/core/extensions/object_ext.dart';
import 'package:flutter_quill_delta_easy_parser/flutter_quill_delta_easy_parser.dart';

extension FragmentExtension on TextFragment {
  EasyText toEasyText() {
    assert(
      data is String,
      'easy_text does not '
      'support ${data.runtimeType} as its '
      'data type',
    );
    return EasyText.fromStr(
      text: data.text(),
      styles: EasyAttributeStyles.fromJson(
        attributes,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'data': data,
      'attributes': attributes,
    };
  }
}
