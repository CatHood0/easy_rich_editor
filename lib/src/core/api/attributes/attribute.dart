class Attribute<T extends Object> {
  /// An unique key for this [Attribute]
  final String key;

  final T value;

  /// Determines if this [Attribute] will be applied
  /// to the parent of the text (whole paragraph/embed/table)
  /// or directly into the selection range
  final bool isInline;

  Attribute({
    required this.key,
    required this.value,
    required this.isInline,
  });

  Attribute.block({
    required this.key,
    required this.value,
  }) : isInline = false;

  Attribute.inline({
    required this.key,
    required this.value,
  }) : isInline = true;
}
