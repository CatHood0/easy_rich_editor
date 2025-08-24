import 'package:easy_text/src/core/attributes/attribute.dart';

class BoldAttribute extends EasyInlineAttribute<bool> {
  BoldAttribute({
    required super.value,
  });

  @override
  String get key => 'strong';
}
