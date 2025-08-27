import '../../../../../attributes.dart';

class ScriptAttribute extends EasyInlineAttribute<String?> {
  const ScriptAttribute([String? value]) : super(value: value);

  const ScriptAttribute.sub() : super(value: 'subscript');
  const ScriptAttribute.sup() : super(value: 'superscript');

  @override
  String get key => 'font-script';

  @override
  ScriptAttribute clone(String? value) {
    return ScriptAttribute(value);
  }
}
