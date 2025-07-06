import 'package:easy_rich_editor/internal.dart';

/// Extractor implementations are used to get a value into the Node. We don't care
/// if the Node passed is the root, or is the exact point with the value, we only need
/// to know, if need to traverse into the Tree of the Nodes, and the subclasses of this
/// base, will implement the logic that they need to make correct extracting operations
abstract class NodeExtractor {
  T getValueFromNode<T>(Node node, {bool needsTraverse = true});
  Node? getNodeOfKey(Node node, String key);
  NodeLocation? getLocationOfNode(Node node, String key);
}
