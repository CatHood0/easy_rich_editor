import 'package:easy_text/src/core/attributes/attribute.dart';

class ItalicAttribute extends EasyInlineAttribute<bool> {
  ItalicAttribute({required super.value});

  @override
  String get key => 'italic';
}
