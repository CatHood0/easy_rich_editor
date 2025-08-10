import '../../../../../easy_rich_editor.dart';

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

    if (node.children.isNotEmpty) {
      _currentNode = node.first;
    } else if (node.next != null) {
      _currentNode = node.next!;
    } else if (node.parent == null) {
      _currentNode = null;
      return false;
    } else {
      while (node.parent != null) {
        node = node.parent!;
        final Node? nextOfParent = node.next;
        if (nextOfParent == null) {
          _currentNode = null;
        } else {
          _currentNode = nextOfParent;
          break;
        }
      }
    }

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
