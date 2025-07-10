import 'package:easy_rich_editor/easy_rich_editor.dart';

/// Extractor implementations are used to get one or more values into the Node.
///
/// We don't care about if:
///
/// 1. the Node passed is the root.
/// 2. the Node passed is the exact point with the value
///
/// We only need to know, if we need to traverse into the Tree of
/// the Nodes, and the subclasses of this base.
///
/// The implementation of this class will implement the logic that
/// they need to make correct extracting operations
abstract class NodeExtractor {
  /// Get the value from the Node passed
  ///
  /// The node passed, usually is the root owner
  /// of the Node. Althrough, you can also pass the direct
  /// value.
  T getValueFromNode<T>(
    Node node,
    bool Function(T value) filter, {
    bool needsTraverse = true,
  });

  /// Get the value from the Node passed
  ///
  ///
  /// The node passed, usually is the root owner
  /// of the Node. Althrough, you can also pass the direct
  /// value.
  Node? getNodeOfKey(Node node, String id);

  /// Get the current location of the Node passed
  /// based on the owner passed. Can be the root of all
  /// Nodes of the Tree, or just its direct owner
  ///
  /// The node passed, usually is the root owner
  /// of the Node. Althrough, you can also pass the direct
  /// value.
  NodeLocation? getLocationOfNode(Node node, String id);

  /// Get all locations of the values that matches with
  /// one passed.
  ///
  /// The node passed, usually is the root nodes that are in the Tree.
  /// Althrough, you can also pass the direct
  /// value.
  List<NodeValueLocation> getLocationsOfValue(
    Node node,
    Object value,
    Limiter limiter, {
    List<int>? path,
    bool caseSensitive = true,
  });
}
