import '../../../easy_rich_editor.dart';

class IllegalNodeException implements Exception {
  final Node node;
  final String message;

  IllegalNodeException({
    required this.node,
    String message = "",
  }) : message = message.isEmpty ? "" : "This was caused by: $message";

  @override
  String toString() {
    return 'IllegalNodeException: found '
        '${node.type}(id: ${node.id}, '
        'start: ${node.globalOffset}, end: ${node.globalEnd}). '
        'Cause of error: $message';
  }
}
