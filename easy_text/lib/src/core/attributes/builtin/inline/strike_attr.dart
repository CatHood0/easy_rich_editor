import 'package:easy_text/src/core/attributes/attribute.dart';

class StrikeAttribute extends EasyInlineAttribute<bool> {
  const StrikeAttribute([bool value = true]) : super(value: value);

  @override
  String get key => 'striketrough';

  @override
  StrikeAttribute clone(value) {
    assert(
      value is bool,
      'the value passed '
      'to $runtimeType is not an '
      'int. Found: $value',
    );
    return StrikeAttribute(value as bool);
  }
}
