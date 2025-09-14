part of 'package:easy_rich_editor/src/core/api/document/nodes/node.dart';

extension NodeOperations on Node {
  void insertNode(
    Node child, {
    int? path,
    bool after = false,
  }) {
    if (isLocked) return;
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
    if (isLocked) return;
    if (!canAddOrRemovedChildren) return;
    assert(
      node.parent == this,
      "The node passed must be at the same Parent of $id",
    );
    if (!contains(node.id)) return;
    final int path = node.path;
    final List<int> deepPath = parent?.deepPath ?? <int>[];
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
        ..deepPath = <int>[...deepPath, path];
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
    EasyAttributeStyles? styles,
    EasyText? frag,
    int fragmentPosition = 0,
    int jumpNodeOffset = 0,
    int jumpOffset = 0,
    int stringLimitLength = 300,
    bool computeParentCache = true,
    NodeModifier? modifier,
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
}
