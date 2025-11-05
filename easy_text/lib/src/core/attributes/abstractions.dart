part of 'attribute.dart';

class UnknownAttribute extends EasyInlineAttribute<dynamic> {
  final String _key;
  UnknownAttribute({
    required String key,
    required super.value,
  }) : _key = key;

  @override
  UnknownAttribute clone(dynamic value) {
    return UnknownAttribute(
      value: value,
      key: key,
    );
  }

  @override
  String get key => _key;
}

abstract class EasyInlineAttribute<T extends Object?> extends EasyAttribute<T> {
  const EasyInlineAttribute({required super.value});

  @override
  bool get isInline => true;

  @override
  bool get exclusive => false;

  @override
  bool canMergeWith(EasyAttribute<Object?> attribute) => true;
}

abstract class EasyExclusiveBlockAttribute<T extends Object?>
    extends EasyAttribute<T> {
  const EasyExclusiveBlockAttribute({required super.value});

  @override
  bool get isInline => false;

  @override
  bool get exclusive => true;

  @override
  bool canMergeWith(EasyAttribute<Object?> attribute) => !attribute.exclusive;
}

abstract class EasyBlockAttribute<T extends Object?> extends EasyAttribute<T> {
  const EasyBlockAttribute({required super.value});

  @override
  bool get isInline => false;

  @override
  bool get exclusive => false;

  @override
  bool canMergeWith(EasyAttribute<Object?> attribute) => true;
}
