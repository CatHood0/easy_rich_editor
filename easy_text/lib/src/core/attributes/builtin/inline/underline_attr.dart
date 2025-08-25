import 'package:easy_text/src/core/attributes/attribute.dart';

class UnderlineAttribute extends EasyInlineAttribute<bool> {
  const UnderlineAttribute([bool value = true]) : super(value: value);

  @override
  String get key => 'underline';

  @override
  UnderlineAttribute clone(bool value) {
    return UnderlineAttribute(value);
  }
}
