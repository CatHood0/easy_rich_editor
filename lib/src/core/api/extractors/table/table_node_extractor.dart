import 'package:easy_rich_editor/easy_rich_editor.dart';
import 'package:easy_rich_editor/src/core/api/document/path/path.dart';

class TableNodeExtractor extends NodeExtractor<Object> {
  @override
  bool canNodeHaveValueType(Node node, Type t) {
    throw UnimplementedError();
  }

  @override
  List<String> formatObjectToStr(Object obj) {
    throw UnimplementedError();
  }

  @override
  List<Node> getLinesFromNode(Node node, {bool Function(Node value)? filter}) {
    throw UnimplementedError();
  }

  @override
  NodeLocation? getLocationOfNode(Node node, String id) {
    throw UnimplementedError();
  }

  @override
  List<NodeValueLocation> getLocationsOfValue(
      Node node, Object value, Limiter limiter,
      {List<int>? path, bool caseSensitive = true}) {
    throw UnimplementedError();
  }

  @override
  Node? getNodeOfKey(Node node, String id) {
    throw UnimplementedError();
  }

  @override
  List<Object> getValueFromNode(
    Node node, {
    bool Function(Node value)? filter,
    bool needsTraverse = true,
  }) {
    throw UnimplementedError();
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
  List<Object> getValuesOfLines(
    Node node, {
    required NodeDepthPath path,
  }) {
    throw UnimplementedError();
  }
}
