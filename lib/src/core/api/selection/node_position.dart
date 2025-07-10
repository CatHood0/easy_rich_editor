import 'package:easy_rich_editor/easy_rich_editor.dart';

class NodePosition {
  final List<int> path;
  final int position;
  final Node node;

  NodePosition({
    required this.path,
    required this.node,
    required this.position,
  });
}
