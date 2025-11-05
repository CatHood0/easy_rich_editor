import 'package:easy_rich_editor/easy_rich_editor.dart';

class NodePathCachePayload {
  final Node root;
  final Node node;
  final int path;
  final int endPath;
  // the direction of the resetting
  final bool after;

  NodePathCachePayload({
    required this.root,
    required this.node,
    required this.path,
    required this.after,
    this.endPath = -1,
  });
}

class NodePathCacheResult {
  NodePathCacheResult();
}
