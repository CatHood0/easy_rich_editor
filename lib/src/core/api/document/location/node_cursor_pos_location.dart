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

  /// The exact offset where the matched
  /// node start
  ///
  /// Using this avoid using `node.offset`
  /// that can be heavy with
  /// [Line] and [EmbedLine]
  final int jumpNodeOffset;

  NodeCursorPosLocation.noFragment({
    required Node node,
    required this.locationOffset,
    required this.jumpNodeOffset,
  })  : location = NodeLocation(
          path: node.deepPath,
          node: node,
        ),
        fragmentOffset = -1,
        jumpOffset = -1,
        fragmentIndex = -1;

  NodeCursorPosLocation({
    required this.location,
    required this.locationOffset,
    required this.jumpNodeOffset,
    this.jumpOffset = -1,
    this.fragmentIndex = -1,
    this.fragmentOffset = -1,
  });

  NodeCursorPosLocation.notFound()
      : location = null,
        fragmentOffset = -1,
        jumpOffset = -1,
        jumpNodeOffset = -1,
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
      jumpNodeOffset: jumpNodeOffset,
      fragmentOffset: fragmentOffset,
      locationOffset: offset,
      jumpOffset: jumpOffset,
    );
  }

  NodeCursorPosLocation copyWith({
    NodeLocation? location,
    int? jumpOffset,
    int? jumpNodeOffset,
    int? fragmentIndex,
    int? fragmentOffset,
    int? locationOffset,
  }) {
    return NodeCursorPosLocation(
      location: location ?? this.location,
      jumpOffset: jumpOffset ?? this.jumpOffset,
      fragmentIndex: fragmentIndex ?? this.fragmentIndex,
      fragmentOffset: fragmentOffset ?? this.fragmentOffset,
      locationOffset: locationOffset ?? this.locationOffset,
      jumpNodeOffset: jumpNodeOffset ?? this.jumpNodeOffset,
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
