import 'package:easy_attribution_text/easy_text.dart';
import 'package:easy_rich_editor/easy_rich_editor.dart';
import 'package:easy_rich_editor/src/core/api/document/nodes/node_iterator.dart';
import 'package:easy_rich_editor/src/core/api/document/path/path.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

class ParagraphNodeExtractor extends NodeExtractor<EasyText> {
  static final ParagraphNodeExtractor _instance = ParagraphNodeExtractor._();

  ParagraphNodeExtractor._();

  static ParagraphNodeExtractor get instance => _instance;

  static bool defaultBlockPrFilter(Node n) => n.isParagraphBlock;

  void _assertBlock(Node n, [NodeSelection? selection]) {
    assert(
      n.isParagraphBlock,
      'expected '
      '"${ParagraphKeys.key}" but '
      'found ${n.shortInfo()}',
    );
    if (selection != null) {
      assert(
          selection.start.path == n.deepPath,
          'selection '
          'must match with '
          'the node specified to get '
          'selected blocks correctly');
    }
  }

  @override
  bool canNodeHaveValueType(Node node, Type t) {
    if (node.isLineBlock) {
      if (t == EasyText || t is String) {
        return true;
      }
      return false;
    }
    return true;
  }

  @override
  Node? getBlock(
    Node node, {
    bool Function(Node value) filter =
        ParagraphNodeExtractor.defaultBlockPrFilter,
    NodeDepthPath path = const <int>[],
  }) {
    return !filter(node) ? null : node;
  }

  @override
  List<Node>? getLines(
    Node node, {
    NodeDepthPath path = const <int>[],
  }) {
    _assertBlock(node);
    return node.children;
  }

  @override
  List<Node> getSelectedBlocks(Node node, NodeSelection selection) {
    if (!selection.isCollapsed) {
      return <Node>[];
    }
    _assertBlock(node, selection);
    if (selection.start.node == null) {
      final Node? block = node
          // commonly, should jump to root
          .jumpToParent()
          // make the query at the root to get the exact node
          .queryPath(selection.start.path)
          ?.jumpToBlock(true);
      return <Node>[
        if (block != null) block,
      ];
    }
    return <Node>[
      selection.start.node!.jumpToBlock()!,
    ];
  }

  @override
  List<Node> getSelectedLines(Node node, NodeSelection selection) {
    if (selection.isCollapsed) {
      return <Node>[
        selection.start.node ??
            node.jumpToParent().queryPath(
                  selection.start.path,
                )!,
      ];
    }
    _assertBlock(node, selection);
    final NodeSelection normalized = selection.normalized;
    return NodeIterator(
      startNode: normalized.start.node!,
      endNode: normalized.end.node!,
    ).toList();
  }

  @override
  EasyText? getValueFromNode(
    Node node, {
    bool Function(Node value)? filter,
    bool needsTraverse = true,
  }) {
    // TODO: implement getValueFromNode
    throw UnimplementedError();
  }

  @override
  List<EasyText> getValuesFromNode(
    Node node, {
    bool Function(Node value)? filter,
    bool needsTraverse = true,
  }) {
    final List<EasyText> fragments = <EasyText>[];

    if (needsTraverse) {
      if (node.isEmpty) return fragments;
      for (final Node subNode in node.children) {
        if (filter != null && !filter(subNode)) {
          continue;
        }
        fragments.addAll(
          getValuesFromNode(
            subNode,
            filter: filter,
            needsTraverse: needsTraverse,
          ),
        );
      }
      return fragments;
    }
    if (node.isLineBlock) {
      if (node.value == null) return fragments;
      if (node.strictlySupportsEasyText) {
        throw UnsupportedError(
          "Expected "
          "EasyTextList type, "
          "founded: ${node.value?.runtimeType} "
          "in ${node.shortInfo()}",
        );
      }
      fragments.addAll(node.texts);
    }
    return fragments;
  }

  @override
  Node? getNodeOfKey(Node node, String key) {
    throw UnimplementedError();
  }

  @override
  List<NodeValueLocation> queryValues(
    Node node,
    Object value,
    Limiter limiter, {
    List<int>? path,
    bool caseSensitive = true,
  }) {
    path ??= <int>[];
    final String valueStr = value as String;
    final RegExp regexp = RegExp(valueStr, caseSensitive: caseSensitive);

    if (!limiter.shouldAvoidTraverseInto(node)) {
      int index = 0;
      final List<NodeValueLocation> locations = <NodeValueLocation>[];

      for (final Node child in node.children) {
        child.updatePathsIfNeeded(index, <int>[...path, index]);
        final List<NodeValueLocation> location = queryValues(
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
      node.supportEasyText,
      "ParagraphNodeExtractor only "
      "accept EasyTextList values to get locations and"
      " found ${node.value.runtimeType}",
    );
    final List<TextRange> ranges = <TextRange>[];
    final String str = node.toPlainText();
    if (str != "" && str.trim().isNotEmpty) {
      final Iterable<RegExpMatch> matches = regexp.allMatches(str);
      if (matches.isEmpty) return <NodeValueLocation>[];
      for (final RegExpMatch match in matches) {
        ranges.add(TextRange(
          start: match.start,
          end: match.end,
        ));
      }
    }

    if (ranges.isEmpty) return <NodeValueLocation>[];
    return <NodeValueLocation>[
      NodeValueLocation(
        location: NodeLocation(path: path, node: node),
        ranges: ranges,
      )
    ];
  }

  @internal
  @override
  List<String> formatObjectToStr(Object obj) {
    assert(obj is EasyTextList || obj is EasyText,
        "The value passed must be a EasyTextList or just EasyText");
    return <String>[
      if (obj is EasyText) _formatFragment(obj),
      if (obj is EasyTextList)
        ...obj.map<String>((EasyText fr) {
          return _formatFragment(fr);
        }),
    ];
  }

  String _formatFragment(EasyText fragment) {
    return fragment.styles.isEmpty
        ? "{${fragment.text} -> ${fragment.styles.toJson()}}"
        : '${fragment.text}';
  }
}
