part of 'package:easy_rich_editor/src/core/api/document/nodes/node.dart';

extension NodeOperations on Node {
  void insertNode(
    Node child, {
    int? path,
    bool after = false,
  }) {
    if (isLocked) return;
    if (!canAddOrRemovedChildren || contains(child.id)) return;
    if (child.parent != null && child.parent != this) {
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
  }

  void removeNode(Node node) {
    if (isLocked) return;
    if (!canAddOrRemovedChildren) return;
    assert(
      node.parent == this,
      "The node passed must be at the same Parent of $id",
    );
    if (!contains(node.id)) return;
    final int path = node.path;
    final Node find = elementAt(path);
    assert(
        find.id == node.id,
        'the node at path($path) '
        'should share same id. '
        'Founded: ${find.shortInfo()}, '
        'expected: ${node.shortInfo()}');
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
        ..deepPath = <int>[...deepPath, path];
      // automtically fixes the paths cached
      // in its siblings
      invalidateCacheOfSiblings(
        node: sibling,
        after: true,
        curPath: path,
      );
    }
  }

  DeltaChangeResult receiveDelta(
    DeltaNode delta, {
    bool removeIfEmpty = false,
    bool transformOffsetWhenRequired = true,
    NodeModifier? modifier,
  }) {
    if (isLocked) return DeltaChangeResult.noExecution();
    modifier ??= NodeModifier.defaultModifier;
    return modifier.receiveDelta(
      this,
      delta,
      removedIfRequired: removeIfEmpty,
      transformOffsetWhenRequired: transformOffsetWhenRequired,
    );
  }

  /// Insert the object at the specified offset
  ///
  /// Some rules that you need
  OperationResult insert(
    int start,
    Object data, {
    EasyText? frag,
    int jumpOffset = 0,
    int jumpNodeOffset = 0,
    NodeModifier? modifier,
    int fragmentPosition = 0,
    int stringLimitLength = 300,
    EasyAttributeStyles? styles,
    bool computeParentCache = true,
  }) {
    if (isLocked) return OperationResult.noExecuted();
    modifier ??= NodeModifier.defaultModifier;
    if (start < 0 || start > dataLength) {
      return OperationResult.noExecuted(NoExecutionReason.invalidStart);
    }
    return modifier.insert(
      this,
      start,
      data,
      frag: frag,
      styles: styles,
      jumpNodeOffset: jumpNodeOffset,
      fragmentPosition: fragmentPosition,
      jumpOffset: jumpOffset,
      stringLimitLength: stringLimitLength,
      computeParentCache: computeParentCache,
    );
  }

  /// Format any character or block using the attributes styles
  ///
  /// - [attributes]: the attributes that will be applied
  /// - [start]: the attributes that will be applied
  OperationResult format(
    int start,
    int? len, {
    required EasyAttributeStyles attributes,
    bool formatBlock = false,
    NodeModifier? modifier,
  }) {
    if (isLocked) return OperationResult.noExecuted();
    modifier ??= NodeModifier.defaultModifier;
    assert(
        formatBlock || !formatBlock && len != null,
        'when you want '
        'to format particular characters, '
        'you need to provide an end');
    return modifier.format(
      this,
      start,
      len ?? 1,
      attributes: attributes,
      formatBlock: formatBlock,
    );
  }

  /// Deletes all the content into the range specified
  OperationResult delete(
    int start,
    int len, {
    EasyText? text,
    int jumpNodeOffset = 0,
    int fragmentPosition = 0,
    int fragmentEndPosition = 0,
    int jumpOffset = 0,
    bool removeEntireNodeWhenEmpty = true,
    bool computeParentCache = true,
    bool forward = false,
    NodeModifier? modifier,
  }) {
    modifier ??= NodeModifier.defaultModifier;
    if (len <= 0 || isLocked) {
      return OperationResult.noExecuted();
    }
    return modifier.delete(
      this,
      start,
      len,
      text: text,
      computeParentCache: computeParentCache,
      forward: forward,
      jumpNodeOffset: jumpNodeOffset,
      jumpOffset: jumpOffset,
      fragmentPosition: fragmentPosition,
      fragmentEndPosition: fragmentEndPosition,
      removeEntireNodeWhenEmpty: removeEntireNodeWhenEmpty,
    );
  }

  void insertAfter(Node entry) {
    if (parent == null) {
      throw Exception('Cannot '
          'insert any child after '
          'this since has '
          'no parent relationship');
    }
    // since we insert an element after this
    // the path changes, and we need a new reallocation
    int lastPathKnowed = path;
    isLast
        ? parent!.children.add(entry)
        : parent!.children.insert(lastPathKnowed.next, entry);
    lastPathKnowed++;
    entry
      ..parent = parent
      // to avoid recomputing of a knowed path
      // just set it
      ..path = lastPathKnowed
      ..deepPath = <int>[...parent!.deepPath, lastPathKnowed];
    parent!.invalidateCache(justCache: true);
    if (parent!._cachedLength != null) {
      parent!._cachedLength = parent!._cachedLength! + 1;
    }
    parent!.invalidateDataOffset(noOffset: true);
    parent!._fastIndexTreePart[entry.id] = entry;
    if (entry.next != null) {
      // reset the current path of the node
      invalidateCacheOfSiblings(
        node: entry,
        after: true,
        curPath: entry.path,
      );
    }
  }

  void insertBefore(Node entry) {
    if (parent == null) {
      throw Exception('Cannot '
          'insert any child after '
          'this since has '
          'no parent relationship');
    }
    // since we insert an element before this
    // the path changes, and we need a new reallocation
    int lastPathKnowed = path;
    assert(path > -1, 'path founded has no valid value: $lastPathKnowed');
    parent!.children.insert(lastPathKnowed, entry);
    entry
      ..parent = parent
      // to avoid recomputing of a knowed path
      // just set it
      ..path = lastPathKnowed
      ..deepPath = <int>[...parent!.deepPath, lastPathKnowed];
    parent!._fastIndexTreePart[entry.id] = entry;
    final int? cachedLength = parent!._cachedLength;
    parent!.invalidateCache(justCache: true);
    if (cachedLength != null) {
      parent!._cachedLength = cachedLength + 1;
    }
    parent!.invalidateDataOffset();
    lastPathKnowed++;
    path = lastPathKnowed;
    deepPath = <int>[
      ...parent!.deepPath,
      lastPathKnowed,
    ];
    if (next != null) {
      invalidateCacheOfSiblings(
        node: this,
        after: true,
        curPath: lastPathKnowed,
      );
    }
  }

}
