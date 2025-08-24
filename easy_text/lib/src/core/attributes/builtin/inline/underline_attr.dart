import 'package:easy_text/src/core/attributes/attribute.dart';

class UnderlineAttribute extends EasyInlineAttribute<bool> {
  UnderlineAttribute({required super.value});

  @override
  String get key => 'underline';
}
