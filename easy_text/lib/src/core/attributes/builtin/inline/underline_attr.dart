import 'package:easy_text/src/core/attributes/attribute.dart';

class UnderlineAttribute extends EasyInlineAttribute<bool> {
  const UnderlineAttribute([bool value = true]) : super(value: value);

  @override
  String get key => 'underline';

  @override
  UnderlineAttribute clone(value) {
    assert(
      value is bool,
      'the value passed '
      'to $runtimeType is not an '
      'int. Found: $value',
    );
    return UnderlineAttribute(value as bool);
  }
}
