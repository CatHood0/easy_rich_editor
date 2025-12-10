import '../../../../../attributes.dart';

class StrikeAttribute extends EasyInlineAttribute<bool?> {
  const StrikeAttribute([bool? value = true]) : super(value: value);

  @override
  String get key => 'striketrough';

  @override
  StrikeAttribute clone(bool? value) {
    return StrikeAttribute(value);
  }
}
