import 'package:easy_attribution_text/easy_text.dart';
import 'package:easy_rich_editor/easy_rich_editor.dart';

/// The location of the current Node and
/// the current ranges that matches with
/// the values of these Nodes
class NodeCursorPosLocation {
  /// The exact location where we can found this [Node]
  /// conformed by a full path and the [Node]
  final NodeLocation? location;

  /// The exact index position of the [TextFragment]
  final int textIndex;

  /// The particular [EasyText] where the cursor match
  final EasyText? text;

  /// The exact relative cursor position
  /// into the [TextFragment] defined in
  /// [textIndex]
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
        text = null,
        fragmentOffset = -1,
        jumpOffset = -1,
        textIndex = -1;

  NodeCursorPosLocation({
    required this.location,
    required this.locationOffset,
    required this.jumpNodeOffset,
    this.text,
    this.jumpOffset = -1,
    this.textIndex = -1,
    this.fragmentOffset = -1,
  });

  NodeCursorPosLocation.notFound()
      : location = null,
        fragmentOffset = -1,
        jumpOffset = -1,
        jumpNodeOffset = -1,
        locationOffset = -1,
        text = null,
        textIndex = -1;

  /// Determines if we not found the [Node]
  bool get notFoundLocation =>
      location == null && textIndex <= -1 && locationOffset <= -1;

  /// Determines if we found the [Node]
  bool get found =>
      location != null && textIndex > -1 && locationOffset > -1 ||
      location != null && node!.hasDefinedValue;

  /// Determines if we found the [Node] but not the [TextFragment]
  /// at the specified [Offset]
  bool get foundButNotFragment =>
      location != null && fragmentOffset <= -1 && textIndex <= -1;

  Node? get node => location?.node;

  /// Determines if we found the [Node] and the [TextFragment] at the
  /// specified [offset]
  bool get foundOffset => found && fragmentOffset >= 0;

  NodeCursorPosLocation withOffset(int offset) {
    return NodeCursorPosLocation(
      location: location,
      textIndex: textIndex,
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
    int? textIndex,
    int? fragmentOffset,
    int? locationOffset,
    EasyText? text,
  }) {
    return NodeCursorPosLocation(
      location: location ?? this.location,
      jumpOffset: jumpOffset ?? this.jumpOffset,
      text: text ?? this.text,
      textIndex: textIndex ?? this.textIndex,
      fragmentOffset: fragmentOffset ?? this.fragmentOffset,
      locationOffset: locationOffset ?? this.locationOffset,
      jumpNodeOffset: jumpNodeOffset ?? this.jumpNodeOffset,
    );
  }

  @override
  String toString() {
    return 'NodeValueLocation(index: $textIndex, '
        'offset: $fragmentOffset, '
        'jumpOffset: $jumpOffset, '
        'locationOffset: $locationOffset, '
        'location: $location)';
  }
}
