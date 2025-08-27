import '../../../../../attributes.dart';

class BoldAttribute extends EasyInlineAttribute<bool> {
  const BoldAttribute([bool value = true]) : super(value: value);

  @override
  String get key => 'strong';

  @override
  BoldAttribute clone(bool value) {
    return BoldAttribute(value);
  }
}
