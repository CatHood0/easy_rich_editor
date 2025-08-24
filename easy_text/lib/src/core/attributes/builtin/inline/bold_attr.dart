import 'package:easy_text/src/core/attributes/attribute.dart';

class BoldAttribute extends EasyInlineAttribute<bool> {
  const BoldAttribute([bool value = true]) : super(value: value);

  @override
  String get key => 'strong';

  @override
  BoldAttribute clone(value) {
    assert(
      value is bool,
      'the value passed '
      'to $runtimeType is not an '
      'int. Found: $value',
    );
    return BoldAttribute(value as bool);
  }
}
