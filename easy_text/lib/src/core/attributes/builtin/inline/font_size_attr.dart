import '../../attribute.dart';

class FontSizeAttribute extends EasyInlineAttribute<double?> {
  const FontSizeAttribute([double? value]) : super(value: value);

  @override
  String get key => 'font-family';

  @override
  FontSizeAttribute clone(double? value) {
    return FontSizeAttribute(value);
  }
}
