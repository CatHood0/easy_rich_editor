import 'package:easy_rich_editor/easy_rich_editor.dart';

class EditorCursorContext {
  /// The last node at its location where the cursor was
  final NodeLocation lastNodeKnowedLocation;
  final NodeSelection selection;

  EditorCursorContext({
    required this.lastNodeKnowedLocation,
    required this.selection,
  });
}
