import 'package:easy_rich_editor/easy_rich_editor.dart';
import 'package:easy_rich_editor/internal.dart';

class EmbedLimiter extends Limiter {
  static final EmbedLimiter _instance = EmbedLimiter._();

  EmbedLimiter._();

  factory EmbedLimiter.instance() {
    return _instance;
  }

  @override
  List<String> get depthLimit => [
        EmbedKeys.key,
        EmbedKeys.childrenKey,
      ];

  @override
  bool shouldAvoidTraverseInto(Node child) {
    assert(depthLimit.isNotEmpty, 'depthLimit cannot be empty');
    assert(
      depthLimit.first == limiterParentOf,
      'depthLimit must have an order. The first '
      'key must be always the parent of its children',
    );
    final String limit = depthLimit.last;

    if (child.type == limit) return true;

    return false;
  }

  @override
  String get limiterParentOf => EmbedKeys.key;

  @override
  int maxDepthLevelToGetData(Node root) {
    throw UnimplementedError();
  }
}
