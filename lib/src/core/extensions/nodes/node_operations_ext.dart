part of 'package:easy_rich_editor/src/core/api/document/nodes/node.dart';

extension NodeOperations on Node {
  void insertNode(
    Node child, {
    int? path,
    bool after = false,
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
      if (_cachedLength != null) {
        _cachedLength = _cachedLength! + 1;
      }
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
    if (_cachedLength != null) {
      _cachedLength = _cachedLength! + 1;
    }
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
        ..path = path
        ..deepPath = <int>[...parent!.deepPath, path];
      invalidateCacheOfSiblings(
        node: sibling,
        after: true,
        curPath: path,
      );
    }
  }

  void receiveNodeChange(int nodeIndex, bool removed) {
    throw UnimplementedError("receiveNodeChange is not implemented yet");
  }

  static const FragmentChangeContext _defaultNonExecutedContext =
      FragmentChangeContext.noExecuted();

  /// Insert the object at the specified offset
  ///
  /// Some rules that you need
  FragmentChangeContext insert(
    int start,
    Object data, {
    int fragmentPosition = 0,
    int jumpNodeOffset = 0,
    int jumpOffset = 0,
    int stringLimitLength = 300,
    bool computeParentCache = true,
    NodeModifier modifier = NodeModifier.defaultModifier,
  }) {
    if (start < 0 || start > dataLength) {
      return FragmentChangeContext.noExecuted();
    }
    return modifier.insert(
      this,
      start,
      data,
      jumpNodeOffset: jumpNodeOffset,
      fragmentPosition: fragmentPosition,
      jumpOffset: jumpOffset,
      stringLimitLength: stringLimitLength,
      computeParentCache: computeParentCache,
    );
  }

  /// Retain is used commonly to apply styles into the subNodes
  FragmentChangeContext retain(
    Map<String, dynamic> attributes,
    int start, {
    int? end,
    bool passToBlockAttributesIfWrapEntireBlock = false,
  }) {
    if (start == end) return FragmentChangeContext.noExecuted();
    return _defaultNonExecutedContext;
  }

  /// Deletes all the content into the range specified
  FragmentChangeContext delete(
    int start,
    int end, {
    int jumpNodeOffset = 0,
    int fragmentPosition = 0,
    int fragmentEndPosition = 0,
    int jumpOffset = 0,
    bool removeEntireNodeWhenEmpty = true,
    bool computeParentCache = true,
    NodeModifier modifier = NodeModifier.defaultModifier,
  }) {
    if (start == end) return FragmentChangeContext.noExecuted();
    return modifier.delete(
      this,
      start,
      end,
      computeParentCache: computeParentCache,
      jumpNodeOffset: jumpNodeOffset,
      jumpOffset: jumpOffset,
      fragmentPosition: fragmentPosition,
      fragmentEndPosition: fragmentEndPosition,
      removeEntireNodeWhenEmpty: removeEntireNodeWhenEmpty,
    );
  }
}
