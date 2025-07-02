import 'package:flutter_quill_delta_easy_parser_visualizer/src/limiters/limiter_base.dart';
import 'package:flutter_quill_delta_easy_parser_visualizer/src/nodes/node.dart';
import '../builders/header/header_keys.dart';

/// HeaderLimiter is esentially like `ParagraphLimiter`
/// but, we prefer just maintaining them divided to have
/// their logic.
class HeaderLimiter extends Limiter {
  static final HeaderLimiter _instance = HeaderLimiter._();

  HeaderLimiter._();

  factory HeaderLimiter.instance() {
    return _instance;
  }

  @override
  List<String> get depthLimit => [
        HeaderKeys.key,
        HeaderKeys.childrenKeys,
        HeaderKeys.textKeys,
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
  String get limiterParentOf => HeaderKeys.key;
}
