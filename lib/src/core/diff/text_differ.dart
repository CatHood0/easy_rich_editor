class TextDiffer {
  final String newTextVersion;
  final List<DiffChange> changes;

  TextDiffer({
    required this.newTextVersion,
    required this.changes,
  });

  bool get hasChanges => changes.isNotEmpty;
}

/// The exact change at the position mentioned
class DiffChange {
  final String type;
  final int startPosition;
  final int endPosition;

  static const String deletion = 'delete';
  static const String addition = 'add';

  DiffChange({
    required this.type,
    required this.startPosition,
    required this.endPosition,
  });
}
