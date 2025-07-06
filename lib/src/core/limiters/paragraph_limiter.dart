import 'package:easy_rich_editor/easy_rich_editor.dart';
import 'package:easy_rich_editor/internal.dart';

class ParagraphLimiter extends Limiter {
  static final ParagraphLimiter _instance = ParagraphLimiter._();

  ParagraphLimiter._();

  factory ParagraphLimiter.instance() {
    return _instance;
  }

  @override
  List<String> get depthLimit => [
        ParagraphKeys.key,
        ParagraphKeys.childrenKey,
        ParagraphKeys.textKey,
      ];

  @override
  bool shouldAvoidTraverseInto(Node child) {
    assert(depthLimit.isNotEmpty, 'depthLimit cannot be empty');
    assert(
      depthLimit.first == limiterParentOf,
      'depthLimit must have an order',
    );
    final String limit = depthLimit.last;

    if (child.type == limit) return true;
    return false;
  }

  @override
  String get limiterParentOf => ParagraphKeys.key;

  @override
  int maxDepthLevelToGetData(Node root) {
    throw UnimplementedError();
  }
}
