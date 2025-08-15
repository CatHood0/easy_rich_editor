part of 'package:easy_rich_editor/src/core/api/document/nodes/node.dart';

extension NodeOperations on Node {
  void insertNode(Node child, {int? path, bool after = false}) {
    if (!canAddOrRemovedChildren || contains(child.id)) return;
    child
      ..invalidateDataOffset()
      ..invalidateCache()
      ..parent = this
      ..unlinkIfNeeded();

    if (path == null || path >= length || isEmpty) {
      _fastIndexTreePart[child.id] = child;
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
    _fastIndexTreePart[child.id] = child;
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
    Node? sibling = node.next;

    children.removeAt(path);
    invalidateCache(justCache: true);
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

  /// Simplifies the deletion, it mades the operation directly at the node
  /// passed. The node passed must contain a value
  ///
  /// - [line]: the [Node] that will be modified.
  ///
  /// - [from]: the relative start offset.
  ///
  /// - [to]: the relative end offset.
  static FragmentChangeContext deleteAtNode(
    Node node,
    int start,
    int end,
  ) {
    assert(start >= end, 'start and end offsets must be normalized');

    if (node.isLocalInRange(start, end)) {
      return node.delete(start, end);
    }
    final Node? block = node.jumpToParentExceptRoot();
    if (block == null) return _defaultNonExecutedContext;
    if (block.isLocalInRange(start, end)) {
      return block.delete(
        start,
        end,
      );
    }
    return _defaultNonExecutedContext;
  }

  /// Simplifies the insertion, it mades the operation directly at the node
  /// passed. The node passed must contain a value
  static FragmentChangeContext insertAtNode(
    Node node,
    int start,
    Object data,
  ) {
    // the current node is the parent
    assert(start >= 0, 'start positive');

    if (node.isLocalInRange(start, start)) {
      return node.insert(start, data);
    }
    final Node? block = node.jumpToParentExceptRoot();
    if (block == null) return _defaultNonExecutedContext;
    if (block.isLocalInRange(start, start)) {
      return block.insert(start, data);
    }
    return _defaultNonExecutedContext;
  }

  //FIXME: when we insert raw newlines in a string
  // them are passed directly to the fragment
  // and are not being converted to a [Line] node
  FragmentChangeContext insert(
    int start,
    Object data, {
    int fragmentPosition = 0,
    int jumpOffset = 0,
    int stringLimitLength = 300,
  }) {
    if (isBlockNode || isRootOwner) {
      final NodeCursorPosLocation location =
          queryPosition(start, inclusive: true);
      if (location.notFoundLocation) return _defaultNonExecutedContext;

      final FragmentChangeContext context = location.node!.insert(
        location.locationOffset,
        data,
        fragmentPosition: fragmentPosition,
        jumpOffset: location.jumpOffset.nonNegative,
        stringLimitLength: stringLimitLength,
      );

      if (context.executed && isBlockNode) {
        jumpToParent()
          ..rebuildNodes(changes: <String, int>{id: 1})
          ..notify();
      }
      return context;
    }

    assert(hasDefinedValue, 'value must be defined');
    assert(start >= 0 && start <= dataLength.next,
        'start: $start is out of range => 0 to ${dataLength.next}');
    final FragmentChangeContext context = insertValueWithContextAt(
      data,
      start,
      fragmentPath: fragmentPosition,
      jumpedOffset: jumpOffset,
      stringLimitLength: stringLimitLength,
    );
    EasyEditorLogger.tree.info('$context');

    // no common, but, can happen when
    // the stringLimitLength is overlapped
    if (context.remainingRanges != null) {
      final Node? parent = jumpToParentExceptRoot();
      EasyEditorLogger.tree.info('The range need to remove '
          'some text between ${context.remainingRanges}');
      parent?.delete(
        parent.convertToGlobal(context.remainingRanges!.start),
        parent.convertToGlobal(context.remainingRanges!.end),
      );
      return context;
    }
    return context;
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
    bool global = false,
  }) {
    return _defaultNonExecutedContext;
  }
}
