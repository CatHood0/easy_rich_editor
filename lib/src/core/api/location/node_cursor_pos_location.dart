import 'package:easy_rich_editor/easy_rich_editor.dart';

/// The location of the current Node
/// and the current ranges that matches with the values of these Nodes
///
/// Tipically this class is used when you use the search option
/// for the editor (it's like searching any type of text)
class NodeCursorPosLocation {
  final NodeLocation? location;
  final int fragmentIndex;
  final int fragmentOffset;
  final int locationOffset;

  NodeCursorPosLocation({
    required this.location,
    required this.fragmentIndex,
    required this.fragmentOffset,
    required this.locationOffset,
  });

  NodeCursorPosLocation.notFound()
      : location = null,
        fragmentOffset = -1,
        locationOffset = -1,
        fragmentIndex = -1;

  bool get notFoundLocation =>
      location == null && fragmentIndex <= -1 && locationOffset <= -1;

  @override
  String toString() {
    return 'NodeValueLocation(at_fragment: $fragmentIndex, location: $location)';
  }
}
