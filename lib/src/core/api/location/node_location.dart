import 'package:easy_rich_editor/internal.dart';

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
}
