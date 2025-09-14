import 'package:easy_rich_editor/easy_rich_editor.dart';
import 'package:easy_rich_editor/src/core/api/document/path/path.dart';
import 'package:meta/meta.dart';

/// Extractor implementations are used to get one or more values,
/// lines or blocks into the specified [Node].
///
/// [NodeExtractor] is the way that we use to 
/// know how we will traverse into the [Node] 
/// structure of the [Node]s 
abstract class NodeExtractor<T extends Object?> {
  bool canNodeHaveValueType(Node node, Type t);

  /// Get the value from the Node passed
  ///
  /// The node passed, usually is direct Node that contains the value.
  T? getValueFromNode(
    Node node, {
    bool Function(Node value)? filter,
    bool needsTraverse = true,
  });

  /// Get the values from the [Node] passed
  ///
  /// The node passed, usually is direct Node that contains the value.
  List<T> getValuesFromNode(
    Node node, {
    bool Function(Node value)? filter,
    bool needsTraverse = true,
  });

  /// Get the exact block at the current [Node]
  ///
  /// Most of the default implementations like [ParagraphNodeExtractor]
  /// just returns the one passed. But in [TableNodeExtractor] filter
  /// columns until get wanted one
  ///
  /// - [node]: The specified [Node] used to get the block
  /// - [filter]: Determines which [Node] will be returned
  /// - [path]: The exact path where we need to search. Tipically is empty
  Node? getBlock(
    Node node, {
    required bool Function(Node value) filter,
    NodeDepthPath path = const <int>[],
  });

  /// Get the lines at the current [Node]
  ///
  /// Most of the default implementations like [ParagraphNodeExtractor]
  /// just returns the lines into the [Paragraph]. 
  ///
  /// [TableNodeExtractor] is different, and it works different when values 
  /// are passed
  ///
  /// - If [path] is empty, get all the lines into the columns.
  /// - If [path] is provided, get the lines at the specified column/block
  /// 
  /// Parameters:
  ///
  /// - [node]: The specified [Node] used to get the block
  /// - [filter]: Determines which [Node] will be returned
  /// - [path]: The exact path where we need to search. Tipically is empty
  List<Node>? getLines(
    Node node, {
    NodeDepthPath path = const <int>[],
  });

  List<Node> getSelectedBlocks(Node node, NodeSelection selection);

  List<Node> getSelectedLines(Node node, NodeSelection selection);

  /// Get the [Node] using the specified [id] 
  Node? getNodeOfKey(Node node, String id);

  /// Get all locations of the values that matches with
  /// one passed.
  ///
  /// Useful for when use "search" option in the toolbar
  /// and need to get the exact position of every values
  List<NodeValueLocation> queryValues(
    Node node,
    Object value,
    Limiter limiter, {
    List<int>? path,
    bool caseSensitive = true,
  });

  @internal
  List<String> formatObjectToStr(Object obj);
}
