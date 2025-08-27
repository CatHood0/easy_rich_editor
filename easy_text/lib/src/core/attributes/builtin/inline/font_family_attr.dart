import '../../../../../attributes.dart';

class FontFamilyAttribute extends EasyInlineAttribute<String?> {
  const FontFamilyAttribute([String? value]) : super(value: value);

  @override
  String get key => 'font-family';

  @override
  FontFamilyAttribute clone(String? value) {
    return FontFamilyAttribute(value);
  }
}
