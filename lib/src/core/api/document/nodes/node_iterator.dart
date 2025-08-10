import '../../../../../easy_rich_editor.dart';
import '../../../exceptions/illegal_node_exception.dart';

/// [NodeIterator] is used to traverse the nodes in visual order (depth-first).
class NodeIterator implements Iterator<Node> {
  /// Creates a NodeIterator.
  NodeIterator({
    required this.startNode,
    this.endNode,
  });

  /// The node to start the iteration with.
  final Node startNode;

  /// The node to end the iteration with.
  final Node? endNode;

  Node? _currentNode;
  bool _began = false;

  @override
  Node get current => _currentNode!;

  @override
  bool moveNext() {
    if (!_began) {
      _currentNode = startNode;
      _began = true;
      return true;
    }

    if (_currentNode == null) {
      return false;
    }
    Node node = _currentNode!;

    if (endNode != null && endNode == node) {
      _currentNode = null;
      return false;
    }

    _currentNode = node.isNotEmpty ? node.first : node.next;

    // there's no chance where we can move
    // to a next place
    if (_currentNode == null) {
      return false;
    }

    // this never happen
    if (node.parent == null && !node.isRootOwner) {
      throw IllegalNodeException(
          node: node,
          message: 'Illegal-Node => Only root can '
              'contain a nullable parent reference');
    }

    if (node.isRootOwner) {
      return false;
    }

    final Node parent = node.jumpToParent(stopAt: (Node node) {
      return node.next != null;
    });

    // if was no found any parent at this point with a next
    // sibling, probably just will return the Root Node,
    // so, we just prefer indicating that there's no way
    // to be moved to next place
    if (parent.isRootOwner) {
      _currentNode = null;
      return false;
    }

    _currentNode = parent.next;
    return _currentNode != null;
  }

  List<Node> toList() {
    final List<Node> result = <Node>[];
    while (moveNext()) {
      result.add(current);
    }
    return result;
  }
}
