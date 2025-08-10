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
  void receiveDelta(
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
      final int lineOffset = offset;
      // if we are selecting the whole line
      // and the content before this one
      // delete this [Node]
      if (delta.start == lineOffset && delta.end == lineOffset) {
        _value = <TextFragment>[];
        // this will be transformed in a new-line
        _dataLength = 1;
        final Node sourceParent = jumpToParentExceptRoot()!;
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
        return;
      }

      if (delta.start < lineOffset && delta.end >= lineOffset) {
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
        _dataLength = 0;
      }
      notify();
      return;
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
        return;
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

      deleteAtNode(this, delta.start, delta.end);

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

      return;
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
          return;
        }

        notify();
        return;
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
    }
  }

  /// Simplifies the deletion, it mades the operation directly at the node
  /// passed. The node passed must contain a value
  ///
  /// - [line]: the [Node] that will be modified.
  ///
  /// - [from]: the start offset.
  ///
  /// - [to]: the end offset.
  ///
  /// - [global]: indicates to the method if the [from] and [to] passed are in global
  /// ranges and need a convertion to be relative.
  void deleteAtNode(Node line, int from, int to, {bool global = false}) {
    assert(line.hasDirectValue(), 'node must contain a value to modify it');
  }

  void insert(int offset, Object data, {int? endOffset}) {}

  /// Retain is used commonly to apply styles into the subNodes
  void retain() {}

  void delete(int from, int to) {}
}
