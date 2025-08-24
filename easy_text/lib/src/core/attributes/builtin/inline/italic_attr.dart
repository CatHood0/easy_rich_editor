import 'package:easy_text/src/core/attributes/attribute.dart';

class ItalicAttribute extends EasyInlineAttribute<bool> {
  const ItalicAttribute([bool value = true]) : super(value: value);

  @override
  String get key => 'italic';

  @override
  ItalicAttribute clone(value) {
    assert(
      value is bool,
      'the value passed '
      'to $runtimeType is not an '
      'int. Found: $value',
    );
    return ItalicAttribute(value as bool);
  }
}
