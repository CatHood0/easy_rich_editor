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
  /// - [delta]: indicates the change into the Node where this is called. the selection must be normalized
  /// - [removedIfRequired]: indicates if the Node will be removed completely from its parent if the deletion wraps the whole [Node]
  /// - [transformOffsetWhenRequired]: indicates if the [offset] will be modified if requires querying ([queryPosition] method) a [Node]. Tipically, this just happen when we call this method in the Root node.
  ///
  /// All the changes in this [DeltaNode] must be applied just internally into this [Node]
  /// if exceeds the [Node] length, just return [false], indicating that this operation must
  /// be managed by the [Tree] manager
  DeltaChangeResult receiveDelta(
    DeltaNode delta, {
    bool removedIfRequired = false,
    bool transformOffsetWhenRequired = true,
  }) {
    assert(
        delta.isNormalized,
        "the delta passed must be "
        "normalized before "
        "making any change");
    // if this is just a [Line] or a [EmbedLine]
    if (delta.newLength == 0 && hasDefinedValue && !isBlockNode) {
      final int lineStartOffset = offset;
      final int lineEndOffset = offset + dataLength;
      // if we are selecting the whole line
      // and the content before this one
      // delete this [Node]
      //
      // First removes all the content
      if (delta.start == lineStartOffset &&
          delta.end == lineEndOffset &&
          isNotBlankText) {
        _value = <TextFragment>[];
        // this will be transformed in a new-line
        _dataLength = 1;
        final Node sourceParent = jumpToParentExceptRoot()!;
        EasyEditorLogger.treeOperations.info(
          "Saving what nodes "
          "changing: [${sourceParent.id}]",
        );
        // jump directly to [Root]
        jumpToParent()
          // saves the content that changes
          ..metadata['requires_rebuild'] =
              HashMap<String, int>.from(<String, int>{
            sourceParent.id: 1,
          })
          // notify to the render editor
          // to take care about the metadata
          // that we passes and just rebuild this
          ..notify();
        return DeltaChangeResult(removed: true, executed: true);
      }

      if (isBlankText && delta.isCollapsed && delta.isDeletion) {
        unlink();
        invalidateDataOffset();
        invalidateCache();
        value = <TextFragment>[];
        _dataLength = null;
        return DeltaChangeResult(
          removed: true,
          removedEntireNode: true,
          executed: true,
        );
      }

      if (delta.start < lineStartOffset && delta.end >= lineEndOffset) {
        unlink();
        invalidateDataOffset();
        invalidateCache();
      }
      // this case should always be true
      // but since we will support custom
      // Node forms, we prefer just adjust
      // our implementations to more be
      // strict
      if (!isBlockNode) {
        _value = <TextFragment>[];
        // this will be transformed in a new-line
        _dataLength = 1;
      } else {
        _dataLength = null;
      }
      notify();
      return DeltaChangeResult(removed: true, executed: true);
    }

    // means that this is a Line
    if (!isBlockNode) {
      _dataLength = delta.newLength;
      final int deltaLength = delta.newLength - delta.oldLength;
      // there's is no length change. Tipically
      // occurs when was selected a portion of text
      // and was replaced with a new text version
      // that has the same length
      if (deltaLength == 0) {
        notify();
        return DeltaChangeResult(executed: false);
      }

      // jump to the most nearest node of the [Root] one
      final Node? block = jumpToParentExceptRoot();

      if (block == null) {
        throw UnimplementedError(
            "not implemented root cases or non parent cases");
      }

      // should never happen
      if (block.path == -1) {
        throw IllegalNodeException(node: block, message: "Invalid Parent");
      }

      if (delta.isDeletion) {
        deleteAtNode(this, delta.start, delta.end);
      } else if (delta.isInsertion) {
        insertAtNode(this, delta.start, delta.end);
      }

      block._dataLength = block.dataLength + deltaLength;

      // if there's a next block, we need to compute it
      if (block.next != null) {
        final Node root = block.parent!;
        // this probably means that we are computing
        // this in the [Root] node, and we cannot allow this
        if (root.isRootOwner) {
          final HashMap<String, int> changes = HashMap();
          int previousOffset = block.globalEnd;
          Node? next = block.next!;
          do {
            next!._offset = previousOffset;
            previousOffset = next.globalEnd;
            changes[next.id] = 1;
            next = next.next;
          } while (next != null);

          // the render editor will take care about this particular
          // property
          root.metadata['requires_rebuild'] = changes;
        }
      }

      return DeltaChangeResult(removed: true, executed: true);
    }

    // this is the parent
    if (isBlockNode) {}
    if (isRootOwner) {
      // only can be registered the blocks (the most nearest parent to the Root)
      final HashMap<String, int> changes = HashMap<String, int>();
      if (delta.isCollapsed) {
        metadata['requires_rebuild'] = changes;
        final NodeCursorPosLocation startNodeLocation =
            queryPosition(delta.start);
        if (startNodeLocation.notFoundLocation) {
          EasyEditorLogger.treeFailures.error("Received a Delta: "
              "$delta, but the Node at the offset "
              "${delta.start} couldn't be founded in the whole Tree");
          return DeltaChangeResult(removed: false, executed: true);
        }

        notify();
        return DeltaChangeResult(executed: true);
      }
      final NodeCursorPosLocation startLoc = queryPosition(delta.start);
      final NodeCursorPosLocation? endLoc = queryPosition(delta.end);
      final List<Node> selectedNodes = NodeIterator(
        startNode: startLoc.location!.node,
        endNode: endLoc?.location?.node,
      ).toList(addEnd: true);
      metadata['requires_rebuild'] = changes;
    }

    // checks if before this Delta, we had some content inside
    // this block
    //
    // if the new length is zero or less, just remove this block
    if (delta.oldLength > 0 && delta.newLength <= 0) {
      final Node parent = jumpToParentExceptRoot()!;
      if (removedIfRequired) {
        unlink();
      }
      children.clear();
      _fastIndexTreePart.clear();
      invalidateDataOffset();
      invalidateCache();
      parent.notify();
      return DeltaChangeResult(
        removedEntireNode: removedIfRequired,
        removed: true,
      );
    }
    return DeltaChangeResult.noExecution();
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
    //TODO: implement this property
    int stringLimitLength = 300,
    bool needQueryPosition = true,
  }) {
    if (isBlockNode || isRootOwner) {
      EasyEditorLogger.tree.info('searching at $start '
          'into $type($id)');
      final NodeCursorPosLocation location = queryPosition(
        start,
        includeLastNode: false,
      );
      EasyEditorLogger.tree.info('Location: $location');
      // we directly ignore at this point this
      if (location.notFoundLocation) return _defaultNonExecutedContext;
      EasyEditorLogger.tree.info('Following query '
          'at ${location.locationOffset} '
          'into ${location.node?.type}(${location.node?.id})');

      final FragmentChangeContext context = location.node!.insert(
        location.locationOffset,
        data,
        fragmentPosition: fragmentPosition,
        stringLimitLength: stringLimitLength,
        needQueryPosition: !location.found,
      );
      if (context.executed && isBlockNode) {
        jumpToParent().rebuildNodes(changes: <String, int>{id: 1});
        notify();
      }
      return context;
    }

    assert(hasDefinedValue, 'value must be defined');
    FragmentChangeContext? context;
    if (needQueryPosition) {
      NodeCursorPosLocation location = queryPosition(
        start,
        includeLastNode: false,
      );

      EasyEditorLogger.tree.info('Location: $location');

      if (location.notFoundLocation) {
        EasyEditorLogger.tree.warn(
          'The Node at $start was not '
          'founded as expected. '
          'Current pos: $type("$id", $deepPath)',
        );
        return _defaultNonExecutedContext;
      }

      if (location.foundButNotFragment) {
        EasyEditorLogger.tree.info(
          'Will try five '
          'attemps to get the '
          'exact fragment '
          'where is the cursor',
        );
        int attemps = 0;
        while (!location.found) {
          if (attemps <= 5 || location.notFoundLocation) {
            EasyEditorLogger.tree.error(
              'The Node at $start was not '
              'founded as expected. '
              'Current pos: $type("$id", $deepPath)',
            );
            return _defaultNonExecutedContext;
          }
          location = location.node!.queryPosition(
            location.locationOffset,
            includeLastNode: false,
          );
          attemps++;
        }
      }

      context = location.location!.node.insertValueWithContextAt(
        data,
        location.locationOffset,
        fragmentPath: location.fragmentIndex,
        jumpedOffset: location.locationOffset,
        stringLimitLength: stringLimitLength,
      );
    } else {
      context = insertValueWithContextAt(
        data,
        start,
        //FIXME: use fragmentPosition
        fragmentPath: 0,
        jumpedOffset: 0,
        stringLimitLength: stringLimitLength,
      );
    }
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
