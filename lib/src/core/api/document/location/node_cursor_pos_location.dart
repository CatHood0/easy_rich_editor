import 'package:easy_rich_editor/easy_rich_editor.dart';

/// The location of the current Node and
/// the current ranges that matches with
/// the values of these Nodes
class NodeCursorPosLocation {
  /// The exact location where we can found this [Node]
  /// conformed by a full path and the [Node]
  final NodeLocation? location;

  /// The exact index position of the [TextFragment]
  final int fragmentIndex;

  /// The exact relative cursor position
  /// into the [TextFragment] defined in
  /// [fragmentIndex]
  final int fragmentOffset;

  /// The exact relative cursor position
  /// into the [Line] that satifies the tests
  final int locationOffset;

  /// The exact offset where the matched
  /// fragment start
  final int jumpOffset;

  NodeCursorPosLocation({
    required this.location,
    required this.locationOffset,
    this.jumpOffset = -1,
    this.fragmentIndex = -1,
    this.fragmentOffset = -1,
  });

  NodeCursorPosLocation.notFound()
      : location = null,
        fragmentOffset = -1,
        jumpOffset = -1,
        locationOffset = -1,
        fragmentIndex = -1;

  /// Determines if we not found the [Node]
  bool get notFoundLocation =>
      location == null && fragmentIndex <= -1 && locationOffset <= -1;

  /// Determines if we found the [Node]
  bool get found =>
      location != null && fragmentIndex > -1 && locationOffset > -1 ||
      location != null && node!.hasDefinedValue;

  /// Determines if we found the [Node] but not the [TextFragment]
  /// at the specified [Offset]
  bool get foundButNotFragment =>
      location != null && fragmentOffset <= -1 && fragmentIndex <= -1;

  Node? get node => location?.node;

  /// Determines if we found the [Node] and the [TextFragment] at the
  /// specified [offset]
  bool get foundOffset => found && fragmentOffset >= 0;

  NodeCursorPosLocation withOffset(int offset) {
    return NodeCursorPosLocation(
      location: location,
      fragmentIndex: fragmentIndex,
      fragmentOffset: fragmentOffset,
      locationOffset: offset,
      jumpOffset: jumpOffset,
    );
  }

  @override
  String toString() {
    return 'NodeValueLocation(index: $fragmentIndex, '
        'offset: $fragmentOffset, '
        'jumpOffset: $jumpOffset, '
        'locationOffset: $locationOffset, '
        'location: $location)';
  }
}
