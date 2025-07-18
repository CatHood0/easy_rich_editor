import 'package:easy_rich_editor/easy_rich_editor.dart';
import 'package:flutter_quill_delta_easy_parser/blocks/text_fragment.dart';

class ParagraphLimiter extends Limiter {
  static final ParagraphLimiter _instance = ParagraphLimiter._();

  ParagraphLimiter._();

  factory ParagraphLimiter.instance() {
    return _instance;
  }

  @override
  List<String> get depthLimit => [
        ParagraphKeys.key,
        ParagraphKeys.lineKey,
      ];

  @override
  bool typeCanContainValue(String type) {
    return type == depthLimit.last;
  }

  @override
  Type get typeValueAccepted => TextFragment;

  @override
  bool ignoreByEmptyValueOrInvalid(Node node) {
    if (node.isEmpty) return true;
    // if is the paragraph node
    if (node.type == limiterParentOf) {
      if (node.length == 1) {
        final Node line = node.firstChild!;
        assert(
          line.type == depthLimit[1],
          'the node into $limiterParentOf is invalid. Node '
          'of type ${line.type} was founded, when we '
          'are expecting a ${ParagraphKeys.lineKey}',
        );
        if (line.isEmpty) return true;
        if (line.length == 1 &&
            line.firstChild.runtimeType != typeValueAccepted) {
          return true;
        }
        if (line.length == 2) {
          final bool firstIsInvalid =
              line.firstChild!.runtimeType != typeValueAccepted ||
                  line.firstChild!.value == null;
          final bool lastIsInvalid =
              line.lastChild!.runtimeType != typeValueAccepted ||
                  line.lastChild!.value == null;
          if (firstIsInvalid && lastIsInvalid) {
            return true;
          }
        }
      }
    }
    return false;
  }

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
  String get limiterParentOf => ParagraphKeys.key;
}
