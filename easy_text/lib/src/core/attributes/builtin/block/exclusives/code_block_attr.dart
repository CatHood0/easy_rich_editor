import '../../../../../../attributes.dart';

class CodeBlockAttribute
    extends EasyExclusiveBlockAttribute<Map<String, dynamic>?> {
  const CodeBlockAttribute({required super.value});

  CodeBlockAttribute.active([
    Map<String, dynamic>? properties,
  ]) : super(value: <String, dynamic>{
          'active': true,
          ...?properties,
        });

  @override
  CodeBlockAttribute clone(Map<String, dynamic>? value) {
    return CodeBlockAttribute(value: value);
  }

  @override
  String get key => 'code-block';
}
