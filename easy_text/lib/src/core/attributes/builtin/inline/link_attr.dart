import 'package:easy_text/src/core/attributes/attribute.dart';

class LinkAttribute extends EasyInlineAttribute<String?> {
  const LinkAttribute([String? value]) : super(value: value);

  @override
  String get key => 'link';

  @override
  LinkAttribute clone(String? value) {
    return LinkAttribute(value);
  }
}
