import 'package:easy_rich_editor/easy_rich_editor.dart';
import 'package:easy_rich_editor/src/core/extensions/object_ext.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_quill_delta_easy_parser/flutter_quill_delta_easy_parser.dart';
import 'package:meta/meta.dart';

class ParagraphNodeExtractor extends NodeExtractor<TextFragment> {
  static final ParagraphNodeExtractor _instance = ParagraphNodeExtractor._();

  ParagraphNodeExtractor._();

  static ParagraphNodeExtractor get instance => _instance;

  @override
  bool canNodeHaveValueType(Node node, Type t) {
    if (node.type == ParagraphKeys.lineKey && t == TextFragment) {
      return true;
    }
    return false;
  }

  @internal
  @override
  List<String> formatObjectToStr(Object obj) {
    assert(obj is Iterable<TextFragment> || obj is TextFragment,
        "The value passed must be a list of fragments or just TextFragment");
    return [
      if (obj is TextFragment) _formatFragment(obj),
      if (obj is Iterable<TextFragment>)
        ...obj.map<String>((TextFragment fr) {
          return _formatFragment(fr);
        }),
    ];
  }

  String _formatFragment(TextFragment fragment) {
    return fragment.attributes != null
        ? "{${fragment.data.toString()} -> ${fragment.attributes.toString()}}"
        : fragment.data.toString();
  }

  @override
  List<TextFragment> getValueFromNode(
    Node node, {
    bool Function(Node value)? filter,
    bool needsTraverse = true,
  }) {
    final List<TextFragment> fragments = [];

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
      if (node.value is! Iterable<TextFragment>) {
        throw UnsupportedError(
          "Expected "
          "List<TextFragment> type, "
          "founded: ${node.value.runtimeType} "
          "in ${node.type}:${node.id}",
        );
      }
      fragments.addAll(node.value!.cast());
    }
    return fragments;
  }

  @override
  List<Node> getLinesFromNode(
    Node node, {
    bool Function(Node value)? filter,
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
