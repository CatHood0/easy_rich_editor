class EasyAttribute<T extends Object?> {
  /// An unique key for this [EasyAttribute]
  final String key;

  final T value;

  /// Determines if this [EasyAttribute] will be applied
  /// to the parent of the text (whole paragraph/embed/table)
  /// or directly into the selection range
  final bool isInline;

  /// Determines if this attribute can be combined with
  /// other attributes
  ///
  /// When this is [true], if other exclusive [EasyAttribute] 
  /// is setted, then this will be automatically removed
  /// since cannot be two exclsuvive [EasyAttribute]s
  final bool exclusive;

  EasyAttribute({
    required this.key,
    required this.value,
    required this.isInline,
    required this.exclusive,
  });

  EasyAttribute.block({
    required this.key,
    required this.value,
    required this.exclusive,
  }) : isInline = false;

  EasyAttribute.inline({
    required this.key,
    required this.value,
  })  : isInline = true,
        exclusive = false;
}
