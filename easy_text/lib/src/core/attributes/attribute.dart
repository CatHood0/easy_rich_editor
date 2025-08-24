part 'abstractions.dart';

abstract class EasyAttribute<T extends Object?> {
  final T value;

  EasyAttribute({required this.value});

  /// An unique key for this [EasyAttribute]
  String get key;

  /// Determines if this [EasyAttribute] will be applied
  /// to the parent of the text (whole paragraph/embed/table)
  /// or directly into the selection range
  bool get isInline;

  /// Determines if this attribute can be combined with
  /// other attributes
  ///
  /// When this is [true], if other exclusive [EasyAttribute]
  /// is setted, then this will be automatically removed
  /// since cannot be two exclsuvive [EasyAttribute]s
  bool get exclusive;
}
