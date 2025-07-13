import 'package:easy_rich_editor/easy_rich_editor.dart';

class NodePathCachePayload {
  final Node root;
  final Node node;
  final int path;
  // the direction of the resetting
  final bool after;

  NodePathCachePayload({
    required this.root,
    required this.node,
    required this.path,
    required this.after,
  });
}

class NodePathCacheResult {
  NodePathCacheResult();
}
