import 'package:easy_rich_editor/easy_rich_editor.dart';

/// The location of the current Node
class NodeLocation {
  final NodeDepthPath path;

  final Node node;

  /// Node owner can be null at some situations
  /// where the root owner is it's direct parent
  final Node? rootOwner;

  NodeLocation({
    required this.path,
    required this.node,
    this.rootOwner,
  });

  NodeLocation.from(this.node)
      : path = node.deepPath,
        rootOwner = node.jumpToParentExceptRoot();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NodeLocation) return false;
    return path.equals(other.path) &&
        node == other.node &&
        rootOwner == other.rootOwner;
  }

  @override
  int get hashCode => Object.hash(
        path,
        node,
        rootOwner,
      );

  @override
  String toString() {
    return 'NodeLocation(path: $path, node: ${node.shortInfo()}, rootOwner: ${rootOwner?.shortInfo()})';
  }
}
