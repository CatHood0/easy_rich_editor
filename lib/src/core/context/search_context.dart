import 'package:easy_rich_editor/src/core/api/location/node_location.dart';

class EditorCursorContext {
  /// The last node at its location where the cursor was
  final NodeLocation lastNodeKnowedLocation;

  EditorCursorContext({
    required this.lastNodeKnowedLocation,
  });
}
