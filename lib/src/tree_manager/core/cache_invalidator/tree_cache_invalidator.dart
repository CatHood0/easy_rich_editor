import 'package:easy_rich_editor/internal.dart';

class TreeCacheInvalidatorPayload {
  final Node root;

  TreeCacheInvalidatorPayload({
    required this.root,
  });
}

class TreeCacheInvalidatorResult {
  final bool end;

  /// only is used when a task is cancelled and recalled at the same time
  final int lastUnresolvedPath;

  TreeCacheInvalidatorResult(
    this.end, {
    this.lastUnresolvedPath = -1,
  });
}
