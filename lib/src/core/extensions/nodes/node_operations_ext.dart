part of 'package:easy_rich_editor/src/core/api/document/nodes/node.dart';

extension NodeOperations on Node {
  void insertNode(Node child, {int? path, bool after = false}) {
    if (!canAddOrRemovedChildren) return;
    if (child.parent != null && child.parent != this) {
      child.unlink();
    }

    child.parent = this;
    _fastIndexTreePart[child.id] = child;

    if (path == null || path >= length) {
      children.add(child);
      invalidateCache(justCache: true);
      invalidateDataOffset();
      return;
    }

    final Node? entry = children.elementAtOrNull(path);

    if (entry == null) {
      throw Exception("Path($path) was not founded into $type($id)");
    }

    if (after) {
      entry.insertAfter(child);
    } else {
      entry.insertBefore(child);
    }
    invalidateCache(justCache: true);
    invalidateDataOffset();
    // reset the current path of the node
    after ? entry.path = path + 1 : child.path = path - 1;
    invalidateCacheOfSiblings(
      node: after ? entry : child,
      after: true,
      curPath: path + 1,
    );
  }

  void removeNode(Node node) {
    if (!canAddOrRemovedChildren) return;
    assert(
      node.parent == this || contains(node.id),
      "The node passed must be at the same Parent of $id",
    );
    final int path = node.path;
    Node? sibling = path + 1 >= length ? null : node.parent!.children[path + 1];

    node.unlink();
    invalidateCache(justCache: true);
    invalidateDataOffset();

    if (sibling != null) {
      sibling.path = path == 0 ? 0 : path - 1;
      final List<int> effectiveDeepPath = <int>[...sibling._deepPath]
        ..[sibling._deepPath.length - 1] = path == 0 ? 0 : path - 1;
      sibling.deepPath = effectiveDeepPath;
      invalidateCacheOfSiblings(
        node: sibling,
        after: true,
        curPath: path == 0 ? 0 : path - 1,
      );
    }
  }
}
