import 'package:easy_rich_editor/easy_rich_editor.dart';
import 'package:easy_rich_editor/src/core/api/document/path/path.dart';

class TableNodeExtractor extends NodeExtractor<Object> {
  @override
  bool canNodeHaveValueType(Node node, Type t) {
    // TODO: implement canNodeHaveValueType
    throw UnimplementedError();
  }

  @override
  List<String> formatObjectToStr(Object obj) {
    // TODO: implement formatObjectToStr
    throw UnimplementedError();
  }

  @override
  Node? getBlock(Node node,
      {required bool Function(Node value) filter,
      NodeDepthPath path = const <int>[]}) {
    // TODO: implement getBlock
    throw UnimplementedError();
  }

  @override
  List<Node>? getLines(Node node, {NodeDepthPath path = const <int>[]}) {
    // TODO: implement getLines
    throw UnimplementedError();
  }

  @override
  Node? getNodeOfKey(Node node, String id) {
    // TODO: implement getNodeOfKey
    throw UnimplementedError();
  }

  @override
  Node? getSelectedBlocks(Node node, NodeSelection selection) {
    // TODO: implement getSelectedBlocks
    throw UnimplementedError();
  }

  @override
  List<Node>? getSelectedLines(Node node, NodeSelection selection) {
    // TODO: implement getSelectedLines
    throw UnimplementedError();
  }

  @override
  Object? getValueFromNode(Node node,
      {bool Function(Node value)? filter, bool needsTraverse = true}) {
    // TODO: implement getValueFromNode
    throw UnimplementedError();
  }

  @override
  List<Object> getValuesFromNode(Node node,
      {bool Function(Node value)? filter, bool needsTraverse = true}) {
    // TODO: implement getValuesFromNode
    throw UnimplementedError();
  }

  @override
  List<NodeValueLocation> queryValues(Node node, Object value, Limiter limiter,
      {List<int>? path, bool caseSensitive = true}) {
    // TODO: implement queryValues
    throw UnimplementedError();
  }
}
