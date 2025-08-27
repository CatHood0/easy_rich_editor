import '../../../../../attributes.dart';

class BackgroundColorAttribute extends EasyInlineAttribute<String?> {
  const BackgroundColorAttribute([String? value]) : super(value: value);

  @override
  String get key => 'bg';

  @override
  BackgroundColorAttribute clone(String? value) {
    return BackgroundColorAttribute(value);
  }
}
