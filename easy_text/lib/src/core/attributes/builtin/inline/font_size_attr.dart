import '../../../../../attributes.dart';

class FontSizeAttribute extends EasyInlineAttribute<double?> {
  const FontSizeAttribute([double? value]) : super(value: value);

  @override
  String get key => 'font-size';

  @override
  FontSizeAttribute clone(double? value) {
    return FontSizeAttribute(value);
  }
}
