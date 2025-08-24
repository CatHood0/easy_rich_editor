import 'package:easy_text/src/core/attributes/attribute.dart';

class StrikeAttribute extends EasyInlineAttribute<bool> {
  StrikeAttribute({required super.value});

  @override
  String get key => 'striketrough';
}
