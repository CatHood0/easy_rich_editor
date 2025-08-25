import 'package:easy_text/src/core/attributes/attribute.dart';

class BackgroundColorAttribute extends EasyInlineAttribute<String?> {
  const BackgroundColorAttribute([String? value]) : super(value: value);

  @override
  String get key => 'bg';

  @override
  BackgroundColorAttribute clone(String? value) {
    return BackgroundColorAttribute(value);
  }
}
