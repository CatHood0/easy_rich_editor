import 'package:easy_rich_editor/easy_rich_editor.dart';

/// The location of the current Node
class NodeLocation {
  final List<int> path;

  final Node node;

  /// Node owner can be null at some situations
  /// where the root owner is it's direct parent
  final Node? rootOwner;

  NodeLocation({
    required this.path,
    required this.node,
    this.rootOwner,
  });

  @override
  String toString() {
    return 'NodeLocation(path: $path, node: ${node.shortInfo()}, rootOwner: ${rootOwner?.shortInfo()})';
  }
}
