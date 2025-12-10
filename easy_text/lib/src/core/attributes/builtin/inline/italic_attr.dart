import '../../../../../attributes.dart';

class ItalicAttribute extends EasyInlineAttribute<bool?> {
  const ItalicAttribute([bool? value = true]) : super(value: value);

  @override
  String get key => 'italic';

  @override
  ItalicAttribute clone(bool? value) {
    return ItalicAttribute(value);
  }
}
