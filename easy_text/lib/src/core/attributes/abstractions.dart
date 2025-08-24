part of 'attribute.dart';

abstract class EasyInlineAttribute<T extends Object?> extends EasyAttribute<T> {
  const EasyInlineAttribute({required super.value});

  /// An unique key for this [EasyAttribute]
  @override
  String get key;

  /// Determines if this [EasyAttribute] will be applied
  /// to the parent of the text (whole paragraph/embed/table)
  /// or directly into the selection range
  @override
  bool get isInline => true;

  /// Determines if this attribute can be combined with
  /// other attributes
  ///
  /// When this is [true], if other exclusive [EasyAttribute]
  /// is setted, then this will be automatically removed
  /// since cannot be two exclsuvive [EasyAttribute]s
  @override
  bool get exclusive => false;
}

abstract class EasyExclusiveBlockAttribute<T extends Object?>
    extends EasyAttribute<T> {
  const EasyExclusiveBlockAttribute({required super.value});

  /// An unique key for this [EasyAttribute]
  @override
  String get key;

  /// Determines if this [EasyAttribute] will be applied
  /// to the parent of the text (whole paragraph/embed/table)
  /// or directly into the selection range
  @override
  bool get isInline => false;

  /// Determines if this attribute can be combined with
  /// other attributes
  ///
  /// When this is [true], if other exclusive [EasyAttribute]
  /// is setted, then this will be automatically removed
  /// since cannot be two exclsuvive [EasyAttribute]s
  @override
  bool get exclusive => true;
}

abstract class EasyBlockAttribute<T extends Object?> extends EasyAttribute<T> {
  const EasyBlockAttribute({required super.value});

  /// An unique key for this [EasyAttribute]
  @override
  String get key;

  /// Determines if this [EasyAttribute] will be applied
  /// to the parent of the text (whole paragraph/embed/table)
  /// or directly into the selection range
  @override
  bool get isInline => false;

  /// Determines if this attribute can be combined with
  /// other attributes
  ///
  /// When this is [true], if other exclusive [EasyAttribute]
  /// is setted, then this will be automatically removed
  /// since cannot be two exclsuvive [EasyAttribute]s
  @override
  bool get exclusive => false;
}
