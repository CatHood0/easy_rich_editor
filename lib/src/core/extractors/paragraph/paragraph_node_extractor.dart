import 'package:easy_rich_editor/easy_rich_editor.dart';
import 'package:flutter/services.dart';

class ParagraphNodeExtractor extends NodeExtractor {
  static final ParagraphNodeExtractor _instance = ParagraphNodeExtractor._();

  ParagraphNodeExtractor._();

  static ParagraphNodeExtractor get instance => _instance;

  @override
  bool canNodeHaveValueType(Node node, Type t) {
    if (node.type == ParagraphKeys.textKey && t == String) {
      return true;
    }
    return false;
  }

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
    bool caseSensitive = true,
  }) {
    if (node.value != null &&
            node.value.runtimeType != limiter.typeValueAccepted ||
        value.runtimeType != limiter.typeValueAccepted) {
      return <NodeValueLocation>[];
    }
    assert(
      value is String,
      "ParagraphNodeExtractor only "
      "accept strings values to get locations",
    );

    path ??= <int>[];
    final String valueStr = value as String;
    final String nodeValueStr = node.value == null ? "" : node.value.toString();
    final RegExp regexp = RegExp(valueStr, caseSensitive: caseSensitive);

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
    if (nodeValueStr != "" && nodeValueStr.trim().isNotEmpty) {
      final List<TextRange> ranges = <TextRange>[];
      final Iterable<RegExpMatch> matches = regexp.allMatches(nodeValueStr);
      if (matches.isEmpty) return <NodeValueLocation>[];
      for (final RegExpMatch match in matches) {
        ranges.add(TextRange(
          start: match.start,
          end: match.end,
        ));
      }

      return <NodeValueLocation>[
        NodeValueLocation(
          location: NodeLocation(path: path, node: node),
          ranges: ranges,
        )
      ];
    }
    return <NodeValueLocation>[];
  }
}
