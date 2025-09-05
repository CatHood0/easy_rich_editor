import 'dart:ui';

import 'package:easy_rich_editor/easy_rich_editor.dart';
import 'package:easy_rich_editor/src/core/api/document/path/path.dart';
import 'package:easy_rich_editor/src/core/extensions/object_ext.dart';
import 'package:flutter_quill_delta_easy_parser/flutter_quill_delta_easy_parser.dart';
import 'package:meta/meta.dart';

class EmbedNodeExtractor extends NodeExtractor<TextFragment> {
  static final EmbedNodeExtractor _instance = EmbedNodeExtractor._();

  EmbedNodeExtractor._();

  static EmbedNodeExtractor get instance => _instance;

  @override
  bool canNodeHaveValueType(Node node, Type t) {
    if (node.isEmbedLine && t == Map) {
      return true;
    }
    return false;
  }

  @internal
  @override
  List<String> formatObjectToStr(Object obj) {
    assert(obj is TextFragment,
        "The value passed must be a list of EasyText but found ${obj.runtimeType}");
    return <String>[
      _formatFragment(obj.castToFragment()),
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
    throw UnimplementedError();
  }

  @override
  List<TextFragment> getValueFromNode(
    Node node, {
    bool Function(Node value)? filter,
    bool needsTraverse = true,
  }) {
    final List<TextFragment> fragments = <TextFragment>[];

    if (needsTraverse) {
      if (node.isEmpty) return fragments;
      for (final Node subNode in node.children) {
        if (filter != null && !filter(subNode)) {
          continue;
        }
        fragments.addAll(
          getValueFromNode(
            subNode,
            filter: filter,
            needsTraverse: needsTraverse,
          ),
        );
      }
      return fragments;
    }
    if (node.isEmbedLine) {
      if (node.value == null) return fragments;
      if (node.value is! TextFragment) {
        throw UnsupportedError(
          "Expected "
          "TextFragment type, "
          "founded: ${node.value.runtimeType} "
          "in ${node.shortInfo()}",
        );
      }
      fragments.add(node.castToFragment());
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
    path ??= <int>[];

    if (!limiter.shouldAvoidTraverseInto(node)) {
      int index = 0;
      final List<NodeValueLocation> locations = <NodeValueLocation>[];
      while (index < node.length) {
        final Node child = node.elementAt(index)
          ..updatePathsIfNeeded(index, <int>[...path, index]);
        final List<NodeValueLocation> location = getLocationsOfValue(
          child,
          value,
          limiter,
          path: <int>[...path, index],
          caseSensitive: caseSensitive,
        );

        locations.addAll(location);

        index++;
      }
      return locations;
    }
    assert(
      node.supportEmbed,
      "EmbedNodeExtractor only "
      "accept TextFragment values to get locations and"
      " found ${node.value.runtimeType}",
    );
    if (node.value?.castToFragment().data == value) {
      return <NodeValueLocation>[
        NodeValueLocation(
          location: NodeLocation(path: path, node: node),
          ranges: <TextRange>[],
        )
      ];
    }
    return <NodeValueLocation>[];
  }

  @override
  Node? getBlock(Node node, NodeDepthPath path) {
    throw UnimplementedError();
  }

  @override
  Node? getBlockAtOffset(Node node, int offset) {
    throw UnimplementedError();
  }

  @override
  List<Node>? getLines(Node node, NodeDepthPath path) {
    throw UnimplementedError();
  }

  @override
  List<Node>? getLinesAtOffset(Node node, int offset) {
    throw UnimplementedError();
  }

  @override
  List<TextFragment> getValuesOfLines(
    Node node, {
    required NodeDepthPath path,
  }) {
    throw UnimplementedError();
  }
}
