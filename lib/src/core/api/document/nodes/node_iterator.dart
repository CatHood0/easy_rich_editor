import '../../../../../easy_rich_editor.dart';

enum IteratorDirection {
  left,
  right,
}

/// [NodeIterator] is used to traverse the nodes in visual order (depth-first).
//FIXME: we need unidirectional iteration since we have the API to know if there
// are previous possible node or next possible nodes
class NodeIterator implements Iterator<Node> {
  /// Creates a NodeIterator.
  NodeIterator({
    required this.startNode,
    this.endNode,
    this.direction = IteratorDirection.right,
  })  : assert(startNode != endNode, 'cannot set the same start and end'),
        assert(
            direction == IteratorDirection.right ||
                direction == IteratorDirection.left &&
                    // selection must not be normalized
                    (endNode == null ||
                        startNode.globalOffset > endNode.globalOffset),
            ''),
        _currentNode = startNode;

  /// The node to start the iteration with.
  final Node startNode;

  /// The direction where the iteration will traverse.
  final IteratorDirection direction;

  /// The node to end the iteration with.
  final Node? endNode;

  Node? _currentNode;

  @override
  Node get current => _currentNode!;

  @override
  bool moveNext() {
    if (_currentNode == null) return false;

    Node node = current;

    if (endNode != null && endNode == node) {
      _currentNode = null;
      return false;
    }

    if (node.parent == null || !node.hasPossibleNextNode) {
      _currentNode = null;
      return false;
    }

    _currentNode = node.jumpToNext(findLines: true);

    return _currentNode != null;
  }

  List<Node> toList() {
    final List<Node> result = <Node>[startNode];
    while (moveNext()) {
      result.add(current);
    }
    return result;
  }
}
