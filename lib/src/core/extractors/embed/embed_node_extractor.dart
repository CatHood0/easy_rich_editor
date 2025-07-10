import 'dart:ui';

import 'package:easy_rich_editor/easy_rich_editor.dart';

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

  @override
  List<NodeValueLocation> getLocationsOfValue(
    Node node,
    Object value,
    Limiter limiter, {
    List<int>? path,
    bool caseSensitive = false,
  }) {
    if (node.value != null &&
            node.value.runtimeType != limiter.typeValueAccepted ||
        value.runtimeType != limiter.typeValueAccepted) {
      return <NodeValueLocation>[];
    }
    assert(
      value is Map<String, dynamic>,
      "EmbedNodeExtractor only "
      "accept Map<String, dynamic> values to get locations",
    );

    path ??= <int>[];

    if (!limiter.shouldAvoidTraverseInto(node)) {
      int index = 0;
      final List<NodeValueLocation> locations = <NodeValueLocation>[];
      while (index < node.length) {
        final Node child = node.elementAt(index);
        child.updatePathsIfNeeded(index, [...path, index]);
        final List<NodeValueLocation> location = getLocationsOfValue(
          child,
          value,
          limiter,
          path: [...path, index],
          caseSensitive: caseSensitive,
        );

        locations.addAll(location);

        index++;
      }
      return locations;
    }
    if (node.value == value) {
      return <NodeValueLocation>[
        NodeValueLocation(
          location: NodeLocation(path: path, node: node),
          ranges: <TextRange>[],
        )
      ];
    }
    return <NodeValueLocation>[];
  }
}
