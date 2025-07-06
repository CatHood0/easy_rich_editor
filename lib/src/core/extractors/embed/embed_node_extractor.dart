import 'package:easy_rich_editor/internal.dart';
import 'package:easy_rich_editor/src/core/extractors/node_extractor_base.dart';

class EmbedNodeExtractor extends NodeExtractor {
  static final EmbedNodeExtractor _instance = EmbedNodeExtractor._();

  EmbedNodeExtractor._();

  static EmbedNodeExtractor get instance => _instance;

  @override
  T getValueFromNode<T>(
    Node node,
    bool Function(T value) filter, {
    bool needsTraverse = true,
  }) {
    throw UnimplementedError();
  }

  @override
  Node? getNodeOfKey(Node node, String key) {
    throw UnimplementedError();
  }

  @override
  NodeLocation? getLocationOfNode(Node root, String key) {
    throw UnimplementedError();
  }
}
