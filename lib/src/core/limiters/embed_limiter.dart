import 'package:easy_rich_editor/easy_rich_editor.dart';

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
  bool typeCanContainValue(String type) {
    return type == depthLimit.last;
  }

  @override
  Type get typeValueAccepted => Map<String, dynamic>;

  @override
  bool ignoreByEmptyValueOrInvalid(Node node) {
    if (node.isEmpty) return true;
    if (node.type == limiterParentOf) {
      if (node.length == 1) {
        final Node embedLine = node.firstChild!;
        assert(
          embedLine.type == depthLimit.last,
          'the node into $limiterParentOf is invalid. Node '
          'of type ${embedLine.type} was founded, when we '
          'are expecting a ${ParagraphKeys.lineKey}',
        );
        if (embedLine.value == null) return true;
        if (embedLine.value.runtimeType != typeValueAccepted) return true;
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
  String get limiterParentOf => EmbedKeys.key;
}
