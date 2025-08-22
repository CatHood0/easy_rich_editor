class Attribute<T extends Object?> {
  /// An unique key for this [Attribute]
  final String key;

  final T value;

  /// Determines if this [Attribute] will be applied
  /// to the parent of the text (whole paragraph/embed/table)
  /// or directly into the selection range
  final bool isInline;

  /// Determines if this attribute can be combined with
  /// other attributes
  ///
  /// When this is [true], if other exclusive [Attribute] 
  /// is setted, then this will be automatically removed
  /// since cannot be two exclsuvive [Attribute]s
  final bool exclusive;

  Attribute({
    required this.key,
    required this.value,
    required this.isInline,
    required this.exclusive,
  });

  Attribute.block({
    required this.key,
    required this.value,
    required this.exclusive,
  }) : isInline = false;

  Attribute.inline({
    required this.key,
    required this.value,
  })  : isInline = true,
        exclusive = false;
}
