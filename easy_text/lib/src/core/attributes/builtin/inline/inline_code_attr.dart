import 'package:easy_text/src/core/attributes/attribute.dart';

class InlineCodeAttribute extends EasyInlineAttribute<bool> {
  const InlineCodeAttribute([bool value = true]) : super(value: value);

  @override
  String get key => 'code';

  @override
  InlineCodeAttribute clone(bool value) {
    return InlineCodeAttribute(value);
  }
}
