import '../../../../../attributes.dart';

class ColorAttribute extends EasyInlineAttribute<String?> {
  const ColorAttribute([String? value]) : super(value: value);

  @override
  String get key => 'inline-color';

  @override
  ColorAttribute clone(String? value) {
    return ColorAttribute(value);
  }
}
