import '../../../easy_text.dart';

/// Represents the change maded in [insert],
/// [delete] and [format] methods
class EasyTextChange {
  /// The start index of the change
  final int start;

  /// The length of the change
  final int length;

  /// The old fragment before the change
  final EasyTextList oldValues;
  /// The new fragment after the change
  final EasyTextList newValues;

  EasyTextChange({
    required this.start,
    required this.length,
    required this.oldValues,
    required this.newValues,
  });
}
