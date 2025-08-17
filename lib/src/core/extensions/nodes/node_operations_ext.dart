part of 'package:easy_rich_editor/src/core/api/document/nodes/node.dart';

extension NodeOperations on Node {
  void insertNode(
    Node child, {
    int? path,
    bool after = false,
    bool noInvalidation = false,
  }) {
    if (!canAddOrRemovedChildren || contains(child.id)) return;
    if (child.parent != null) {
      child.unlinkIfNeeded();
    }
    child
      ..invalidateDataOffset()
      ..invalidateCache()
      ..parent = this;

    _fastIndexTreePart[child.id] = child;
    if (path == null || path >= length || isEmpty) {
      children.add(child);
      invalidateCache(justCache: true);
      parent?.invalidateDataOffset();
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
    parent?.invalidateDataOffset();
    invalidateCacheOfSiblings(
      node: after ? entry : child,
      after: true,
      curPath: path + 1,
    );
  }

  void removeNode(Node node) {
    if (!canAddOrRemovedChildren) return;
    assert(
      node.parent == this,
      "The node passed must be at the same Parent of $id",
    );
    if (!contains(node.id)) return;
    final int path = node.path;
    final Node? find = elementAtOrNull(path);
    if (find == null || find.id != node.id) return;
    Node? sibling = node.next;

    children.removeAt(path);

    if (_cachedLength != null) {
      _cachedLength = (_cachedLength! - 1).nonNegative;
    }
    invalidateDataOffset();
    _fastIndexTreePart.remove(node.id);

    if (sibling != null) {
      sibling
        ..path = path.prev.nonNegative
        ..deepPath = <int>[...parent!.deepPath, path.prev.nonNegative];
      invalidateCacheOfSiblings(
        node: sibling,
        after: true,
        curPath: path.prev.nonNegative,
      );
    }
  }

  void receiveNodeChange(int nodeIndex, bool removed) {
    throw UnimplementedError("receiveNodeChange is not implemented yet");
  }

  static const FragmentChangeContext _defaultNonExecutedContext =
      FragmentChangeContext.noExecuted();

  FragmentChangeContext insert(
    int start,
    Object data, {
    int fragmentPosition = 0,
    int jumpOffset = 0,
    int stringLimitLength = 300,
    NodeModifier modifier = NodeModifier.defaultModifier,
  }) {
    return modifier.insert(
      this,
      start,
      data,
      fragmentPosition: fragmentPosition,
      jumpOffset: jumpOffset,
      stringLimitLength: stringLimitLength,
    );
  }

  /// Retain is used commonly to apply styles into the subNodes
  FragmentChangeContext retain(
    Map<String, dynamic> attributes,
    int start, {
    int? end,
    bool passToBlockAttributesIfWrapEntireBlock = false,
  }) {
    return _defaultNonExecutedContext;
  }

  FragmentChangeContext delete(
    int start,
    int end, {
    int fragmentPosition = 0,
    int jumpOffset = 0,
    NodeModifier modifier = NodeModifier.defaultModifier,
  }) {
    return modifier.delete(
      this,
      start,
      end,
    );
  }
}
