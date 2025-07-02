import 'package:flutter_quill_delta_easy_parser_visualizer/src/builders/paragraph/paragraph_keys.dart';
import 'package:flutter_quill_delta_easy_parser_visualizer/src/limiters/limiter_base.dart';
import 'package:flutter_quill_delta_easy_parser_visualizer/src/nodes/node.dart';

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
  bool shouldAvoidTraverseInto(EasyVilNode child) {
    assert(depthLimit.isNotEmpty, 'depthLimit cannot be empty');
    assert(
      (depthLimit.length == 1 && depthLimit.first == limiterParentOf) ||
          (depthLimit.first == limiterParentOf &&
              depthLimit.last != depthLimit.last),
      'depthLimit must have an order',
    );
    final String lastChildLimit = depthLimit.last;

    if (child.type == lastChildLimit) return false;
    return true;
  }

  @override
  String get limiterParentOf => ParagraphKeys.key;

  @override
  int maxDepthLevelToGetData(EasyVilNode root) {
    throw UnimplementedError();
  }
}
