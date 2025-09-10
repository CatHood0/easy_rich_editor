import 'package:easy_rich_editor/easy_rich_editor.dart';

class NodeBuilder {
  final String key;
  final NodeModifier modifier;
  final NodeExtractor extractor;
  final Limiter limiters;

  NodeBuilder({
    required this.key,
    required this.modifier,
    required this.extractor,
    required this.limiters,
  });
}
