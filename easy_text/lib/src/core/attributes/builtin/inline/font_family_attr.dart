import 'package:easy_text/src/core/attributes/attribute.dart';

class FontFamilyAttribute extends EasyInlineAttribute<String?> {
  const FontFamilyAttribute([String? value]) : super(value: value);

  @override
  String get key => 'font-family';

  @override
  FontFamilyAttribute clone(String? value) {
    return FontFamilyAttribute(value);
  }
}
