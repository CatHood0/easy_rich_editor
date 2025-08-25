part of 'attribute.dart';

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
