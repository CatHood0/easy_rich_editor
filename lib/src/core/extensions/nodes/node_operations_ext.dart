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
      parent!.invalidateDataOffset();
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
    parent!.invalidateDataOffset();
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

  void receiveNodeChange(int nodeIndex, bool removed) {
    throw UnimplementedError("receiveNodeChange is not implemented yet");
  }

  /// Receives a Delta that contains the change do it to this element
  ///
  /// All the changes in this [DeltaNode] must be applied just internally into this [Node]
  /// if exceeds the Node length, just return false, indicating that this operation must
  /// be managed by the [Tree] manager
  void receiveDelta(DeltaNode delta, {bool removedIfRequired = false}) {
    // if this is just a [Line] or a [EmbedLine]
    if (delta.newLength == 0 && hasDefinedValue) {
      if (removedIfRequired) {
        unlink();
        invalidateDataOffset();
        invalidateCache();
      }
      _value = <TextFragment>[];
      // this will be transformed in a new-line
      _dataLength = 1;
      return;
    }

    // means that this is a Line
    if (!isBlockNode) {
      _dataLength = delta.newLength;
      if (parent != null) {
        final Node root = parent!.jumpToParent();
        // TODO: check how you can avoid invalidate the data length
        // of the parent, and just recomputing with the Delta values
        // which should be the new length for the parent
        if (root.metadata['root'] as bool? ?? false) {
          final int path = parent!.path;
          for (int i = path + 1; i < root.length; i++) {
            //TODO: how too
          }
        }
      }
      return;
    }

    // checks if before this Delta, we had some content inside
    // this block
    //
    // if the new length is zero or less, just remove this block
    if (delta.oldLength > 0 && delta.newLength <= 0) {
      unlink();
      invalidateDataOffset();
      invalidateCache();
      children.clear();
      _fastIndexTreePart.clear();
    }

    // ======= Containers section ======== \\
    final NodeCursorPosLocation node = queryPositionLinear(
      delta.start,
      includeLastNode: true,
    );
  }

  /// Simplifies the deletion, it mades the operation directly at the node
  /// passed. The node passed must contain a value
  void deleteAtNode(Node line, int from, int to) {
    assert(line.hasDirectValue(), 'node must contain a value to modify it');
  }

  void insert(int offset, Object data, {int? endOffset}) {}

  /// Retain is used commonly to apply styles into the subNodes
  void retain() {}

  void delete(int from, int to) {}
}
