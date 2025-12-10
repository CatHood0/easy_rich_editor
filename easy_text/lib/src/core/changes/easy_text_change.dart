import 'package:dart_quill_delta/dart_quill_delta.dart';

/// Represents the change maded in [insert],
/// [delete] and [format] methods
class EasyTextChange {
  /// The start index of the change
  final int start;

  /// The length of the change
  final int length;

  /// The old fragment before the change
  final Delta delta;
  /// The new fragment after the change
  final Delta inverted;

  EasyTextChange({
    required this.start,
    required this.length,
    required this.delta,
    required this.inverted,
  });
}
