enum ActionType {
  delete,
  update,
  updateAttributes,
  insert,
  move,
}

class FragmentActions {
  final Object? data;
  final Map<String, dynamic>? metadata;

  /// The start offset where this occurs
  final int startOffset;

  /// The end offset where this actions ends
  final int? endOffset;

  /// Determines the type of this action
  final ActionType type;

  FragmentActions({
    required this.data,
    required this.type,
    required this.startOffset,
    this.metadata,
    this.endOffset,
  });

  FragmentActions.insert({
    required this.data,
    required this.startOffset,
    this.endOffset,
    this.metadata,
  }) : type = ActionType.insert;

  FragmentActions.delete({
    required this.data,
    required this.startOffset,
    required this.endOffset,
    required this.metadata,
  }) : type = ActionType.delete;

  FragmentActions.update({
    required this.data,
    required this.startOffset,
    required this.endOffset,
    required this.metadata,
  }) : type = ActionType.update;

  FragmentActions.updateAttrs({
    required this.data,
    required this.startOffset,
    required this.endOffset,
    required this.metadata,
  })  : assert(
            endOffset != null,
            'endOffset must be '
            'defined to update attributes'),
        assert(
            metadata != null,
            'metadata must be defined '
            'to update attributes'),
        type = ActionType.updateAttributes;

  FragmentActions.move({
    required this.data,
    required this.startOffset,
    required this.endOffset,
    required this.metadata,
  }) : type = ActionType.move;
}
