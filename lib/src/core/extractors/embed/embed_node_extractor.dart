import 'dart:ui';

import 'package:easy_rich_editor/easy_rich_editor.dart';
import 'package:easy_rich_editor/src/core/extensions/object_ext.dart';
import 'package:flutter_quill_delta_easy_parser/flutter_quill_delta_easy_parser.dart';
import 'package:meta/meta.dart';

class EmbedNodeExtractor extends NodeExtractor<Map<String, dynamic>> {
  static final EmbedNodeExtractor _instance = EmbedNodeExtractor._();

  EmbedNodeExtractor._();

  static EmbedNodeExtractor get instance => _instance;

  @override
  bool canNodeHaveValueType(Node node, Type t) {
    if (node.type == EmbedKeys.childrenKey && t == Map) {
      return true;
    }
    return false;
  }

  @internal
  @override
  List<String> formatObjectToStr(Object obj) {
    assert(obj is List<TextFragment>,
        "The value passed must be a list of TextFragment");
    return [
      if (obj is Iterable<TextFragment>)
        ...obj.map<String>((TextFragment fr) {
          return _formatFragment(fr);
        }),
    ];
  }

  String _formatFragment(TextFragment obj) {
    return obj.data.toString();
  }

  @override
  List<Node> getLinesFromNode(
    Node node, {
    bool Function(Node value)? filter,
  }) {
    // TODO: implement getLinesFromNode
    throw UnimplementedError();
  }

  @override
  List<Map<String, dynamic>> getValueFromNode(
    Node node, {
    bool Function(Node value)? filter,
    bool needsTraverse = true,
  }) {
    final List<Map<String, dynamic>> fragments = [];

    if (needsTraverse) {
      if (node.isEmpty) return fragments;
      Node? subNode = node.firstChild;
      while (subNode != null) {
        if (filter != null && !filter(subNode)) {
          subNode = subNode.next;
          continue;
        }
        fragments.addAll(
          getValueFromNode(
            subNode,
            filter: filter,
            needsTraverse: needsTraverse,
          ),
        );
        subNode = subNode.next;
      }
      return fragments;
    }
    if (node.type == ParagraphKeys.lineKey) {
      if (node.value == null) return fragments;
      if (node.value is! Iterable<Map<String, dynamic>>) {
        throw UnsupportedError(
          "Expected "
          "List<Map<String, dynamic>> type, "
          "founded: ${node.value.runtimeType} "
          "in ${node.type}:${node.id}",
        );
      }
      fragments.addAll(node.value!.cast());
    }
    return fragments;
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
