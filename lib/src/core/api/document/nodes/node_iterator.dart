import '../../../../../easy_rich_editor.dart';

/// [NodeIterator] is used to traverse the nodes in visual order (depth-first).
class NodeIterator implements Iterator<Node> {
  NodeIterator({
    required this.startNode,
    this.endNode,
  });

  final Node startNode;
  final Node? endNode;

  Node? _currentNode;
  bool _began = false;
  final List<int> _indexStack = <int>[];

  @override
  Node get current => _currentNode!;

  @override
  bool moveNext() {
    if (!_began) {
      _currentNode = startNode;
      _began = true;
      return true;
    }

    if (_currentNode == null) return false;
    if (endNode != null && _currentNode == endNode) {
      _currentNode = null;
      return false;
    }

    // 1. Depth first
    if (_currentNode!.children.isNotEmpty) {
      _indexStack.add(0); // Guarda índice actual antes de bajar
      _currentNode = _currentNode!.children.first;
      return true;
    }

    // 2. If no children, jump to next sibling or go to its parent
    Node? node = _currentNode;
    while (node != null && node.parent != null) {
      final siblings = node.parent!.children;
      final currentIndex = siblings.indexOf(node);

      if (currentIndex != -1 && currentIndex < siblings.length - 1) {
        _currentNode = siblings[currentIndex + 1];
        if (_indexStack.isNotEmpty) {
          _indexStack[_indexStack.length - 1] =
              currentIndex + 1; // Actualiza índice
        }
        return true;
      } else {
        node = node.parent;
        if (_indexStack.isNotEmpty) _indexStack.removeLast();
      }
    }

    _currentNode = null;
    return false;
  }

  List<Node> toList() {
    final List<Node> result = <Node>[];
    while (moveNext()) {
      result.add(current);
    }
    return result;
  }
}
