part of 'package:easy_rich_editor/src/core/api/document/nodes/node.dart';

extension NodeSearchExt on Node {
  /// Queries the child [Node] at [offset] in this [Node] using binary search algorithm.
  ///
  /// The result may contain the found node or `null` if no node is found
  /// at specified offset.
  ///
  /// - [NodeCursorPosLocation.fragmentIndex] is set to relative fragment index
  /// within returned child node
  /// - [NodeCursorPosLocation.fragmentOffset] is set to relative offset into the fragments
  /// within returned child node which points at the same character position in the document
  /// - [NodeCursorPosLocation.locationOffset] is set to a valid offset that can be used to make any operation into
  /// the node where the [cursorPos] match
  NodeCursorPosLocation queryPosition(
    int cursorPos, {
    bool inclusive = false,
  }) {
    if (cursorPos < 0 || cursorPos > dataLength) {
      EasyEditorLogger.treeFailures.debug('QueryPosition('
          'pos: $cursorPos, '
          'incl: $inclusive) => '
          'Was not founded in ${shortInfo()}');
      return NodeCursorPosLocation.notFound();
    }

    if (hasDefinedValue) {
      EasyEditorLogger.tree.debug('QueryPosition('
          'pos: $cursorPos, '
          'incl: $inclusive) => '
          'Searching in fragments of ${shortInfo()}');
      return queryOffset(cursorPos, inclusive: true);
    }

    if (inclusive && cursorPos == dataLength && isNotEmpty) {
      final Node lastNode = children.last;
      EasyEditorLogger.tree.debug('QueryPosition('
          'pos: $cursorPos, '
          'incl: $inclusive) => '
          'Found node at end of parent ${shortInfo()}. '
          'Node: ${lastNode.shortInfo()}');
      return NodeCursorPosLocation(
        location: NodeLocation.from(lastNode),
        jumpNodeOffset: lastNode.offset,
        jumpOffset: lastNode.isBlockNode ||
                !lastNode.supportEasyText ||
                lastNode.isBlankText
            ? -1
            : (lastNode.dataLength - lastNode.texts.last.length).nonNegative,
        text: lastNode.supportEasyText && lastNode.isNotBlankText
            ? lastNode.texts.last
            : null,
        textIndex: lastNode.isBlockNode || !lastNode.hasDefinedValue
            ? -1
            : !lastNode.supportEasyText
                ? 0
                : lastNode.texts.length.decr.nonNegative,
        fragmentOffset: lastNode.isBlockNode || !lastNode.hasDefinedValue
            ? -1
            : lastNode.dataLength,
        locationOffset: lastNode.dataLength,
      );
    }

    int low = 0;
    int high = length.decr.nonNegative;
    Node? foundNode;
    int localOffset = 0;
    int nodeOffset = 0;
    while (low <= high) {
      final int mid = (low + high) ~/ 2;
      final Node node = children[mid];
      nodeOffset = node.offset;
      final int nodeEnd = nodeOffset + node.dataLength;

      final bool containsOffset = !node.isBlockNode
          ? cursorPos >= nodeOffset && cursorPos <= nodeEnd
          : cursorPos >= nodeOffset && cursorPos < nodeEnd;
      if (containsOffset) {
        foundNode = node;
        localOffset = cursorPos - nodeOffset;
        EasyEditorLogger.tree.debug('QueryPosition('
            'pos: $cursorPos, '
            'incl: $inclusive, '
            'local: $localOffset) => '
            'Found at ${node.shortInfo()}');
        break;
      } else if (cursorPos < nodeOffset) {
        high = mid - 1;
      } else {
        low = mid + 1;
      }
    }

    if (foundNode == null) {
      EasyEditorLogger.treeFailures.debug('QueryPosition('
          'pos: $cursorPos, '
          'incl: $inclusive) => '
          'Was not founded in ${shortInfo()}');
      return NodeCursorPosLocation.notFound();
    }

    if (foundNode.isBlockNode || !foundNode.hasDefinedValue) {
      return NodeCursorPosLocation.noFragment(
        node: foundNode,
        jumpNodeOffset: nodeOffset,
        locationOffset: localOffset,
      );
    }

    return foundNode
        .queryOffset(localOffset, inclusive: true)
        .copyWith(jumpNodeOffset: nodeOffset);
  }

  NodeCursorPosLocation queryOffset(
    int cursorPos, {
    bool inclusive = false,
  }) {
    if (cursorPos < 0 || cursorPos > dataLength) {
      return NodeCursorPosLocation.notFound();
    }

    if (supportEmbed) {
      final TextFragment frag = value.castToFragment();
      final int fragLength = frag.length;
      if (cursorPos < fragLength || inclusive && cursorPos <= fragLength) {
        return NodeCursorPosLocation(
          location: NodeLocation(
            path: <int>[...deepPath],
            node: this,
          ),
          jumpNodeOffset: -1,
          textIndex: 0,
          fragmentOffset: cursorPos,
          locationOffset: cursorPos,
          jumpOffset: 0,
        );
      }
    }

    if (supportEasyText) {
      int fragOffset = 0;
      int i = 0;
      for (EasyText frag in texts) {
        final int fragmentLength = frag.length;

        final int fragEnd = fragOffset + fragmentLength;
        // if the cursor is in this exact fragment
        if (cursorPos < fragEnd || inclusive && cursorPos <= fragEnd) {
          return NodeCursorPosLocation(
            location: NodeLocation(
              path: <int>[...deepPath],
              node: this,
            ),
            jumpNodeOffset: -1,
            text: frag,
            textIndex: i,
            fragmentOffset: cursorPos - fragOffset,
            locationOffset: cursorPos,
            jumpOffset: fragOffset,
          );
        }
        i++;
        fragOffset += fragmentLength;
      }
    }

    return NodeCursorPosLocation.noFragment(
      node: this,
      jumpNodeOffset: -1,
      locationOffset: cursorPos,
    );
  }

  Object? queryObjectAtOffset(
    int cursorPos, {
    bool inclusive = false,
  }) {
    if (cursorPos < 0 || cursorPos > dataLength) {
      return null;
    }

    if (supportEmbed) {
      final TextFragment frag = value.castToFragment();
      final int fragLength = frag.length;
      if (cursorPos < fragLength || inclusive && cursorPos <= fragLength) {
        return NodeCursorPosLocation(
          location: NodeLocation(
            path: <int>[...deepPath],
            node: this,
          ),
          jumpNodeOffset: -1,
          textIndex: 0,
          fragmentOffset: cursorPos,
          locationOffset: cursorPos,
          jumpOffset: 0,
        );
      }
      return null;
    }

    if (supportEasyText) {
      int fragOffset = 0;
      for (EasyText frag in texts) {
        final int fragmentLength = frag.length;
        final int fragEnd = fragOffset + fragmentLength;
        // if the cursor is in this exact fragment
        if (cursorPos < fragEnd || inclusive && cursorPos <= fragEnd) {
          return frag;
        }
        fragOffset += fragmentLength;
      }
    }

    return null;
  }

  /// Queries the child [Node] at [offset] in this [Node].
  ///
  /// The result may contain the found node or `null` if no node is found
  /// at specified offset.
  NodeCursorPosLocation queryPositionLinear(
    int cursorPos, {
    bool includeLastNode = false,
  }) {
    if (cursorPos < 0 || cursorPos > dataLength) {
      return NodeCursorPosLocation.notFound();
    }

    int offset = 0;
    for (final Node node in children) {
      final int len = node.dataLength;
      offset += len;
      // at this point, the cursor can be used
      // as a local position in the node, instead
      // a global one
      if (cursorPos < len ||
          (includeLastNode && cursorPos == len && node.isLast)) {
        // this means that we are in a `Node` of type `Line` or `EmbedLine`
        int i = 0;
        if (node.supportEasyText && node.isNotBlankText) {
          final EasyTextList frags = node.castToEasyText();
          int fragOffset = 0;
          for (EasyText frag in frags) {
            final int fragmentLength = frag.length;

            final int effectivePosition = fragOffset + fragmentLength;
            // if the cursor is in this exact fragment
            if (cursorPos < effectivePosition) {
              return NodeCursorPosLocation(
                location: NodeLocation(
                  path: <int>[...node.deepPath],
                  node: node,
                ),
                jumpNodeOffset: offset,
                text: frag,
                textIndex: i,
                fragmentOffset: cursorPos - fragOffset,
                locationOffset: cursorPos,
              );
            }

            fragOffset += fragmentLength;
            i++;
          }
        }

        return NodeCursorPosLocation.noFragment(
          node: node,
          jumpNodeOffset: offset,
          locationOffset: cursorPos,
        );
      }
      cursorPos -= len;
    }

    return NodeCursorPosLocation.notFound();
  }

  /// Search easily the node at the index passed using ranges
  Node? fastSearch(int index) {
    throw UnimplementedError("fastSearch is not implemented yet");
  }

  Node elementAt(int index) => children[index];

  Node? elementAtOrNull(int index) =>
      isEmpty || index < 0 || index >= length ? null : children[index];

  /// Whether this [Node] is into the N.T.P registry
  bool contains(String id) => _fastIndexTreePart[id] != null;

  /// Determines if inside this node the range is valid
  bool isLocalInRange(int start, int end) {
    final bool startInRange = start >= 0 && start < dataLength;
    final bool endInRange = end >= start && end < dataLength;

    return startInRange && endInRange;
  }

  /// Transform a global point, to a relative point to the parent
  int convertToLocal(int point) {
    final int effectiveLocal = point - globalOffset;
    return effectiveLocal.nonNegative;
  }

  /// Transform a relative point, to a global point in the `Document`
  int convertToGlobal(int point) {
    final int effectiveLocal = point + globalOffset;
    return effectiveLocal;
  }

  /// Determines if inside this node the global range is valid
  bool isInRange(int start, int end) {
    final int globalOff = globalOffset;
    final bool startInRange =
        globalOff <= start && start < (globalOff + dataLength);
    final bool endInRange = globalOff <= end && end < (globalOff + dataLength);

    return startInRange && endInRange;
  }

  /// Returns `true` if the position is not after or into the range of the node
  bool isBehind(int pos, {bool local = false}) {
    final int nodeOffset = local ? offset : globalOffset;
    return pos < nodeOffset;
  }

  /// Returns `true` if this node contains character at specified [offset] in
  /// the document.
  bool containsOffset(int pos, {bool local = false, bool inclusive = false}) {
    final int nodeOffset = local ? offset : globalOffset;
    return inclusive
        ? pos >= nodeOffset && pos <= (nodeOffset + dataLength)
        : pos >= nodeOffset && pos < (nodeOffset + dataLength);
  }

  /// Returns `true` if this [Node] contains the relative character [offset]
  /// in the document.
  bool containsSelection(NodeSelection selection) {
    final int nodeEnd = dataLength;
    return selection.start.position >= 0 && selection.end.position <= nodeEnd;
  }

  /// Whether this [Node] is into the [selection] range
  bool inSelection(NodeSelection selection) {
    if (selection.start.path <= selection.end.path) {
      return selection.start.path <= deepPath && deepPath <= selection.end.path;
    } else {
      return selection.end.path <= deepPath && deepPath <= selection.start.path;
    }
  }

  /// Returns the [Node] that matches with the [id] passed
  ///
  /// - [deep]: Determines if this will search the [Node] into its children
  Node? findById(String id, {bool deep = true}) {
    if (this.id == id) return this;
    if (isEmpty || !canAddOrRemovedChildren) return null;

    if (contains(id)) {
      return _fastIndexTreePart[id]!;
    }

    if (deep) {
      for (Node child in children) {
        if (child.id == id) return child;
        final Node? node = child.findById(id, deep: deep);
        if (node != null) return node;
      }
    }

    return null;
  }

  /// Whether this [Node] has a [next] node into its
  /// parent or the siblings of its parent
  bool get hasPossibleNextNode {
    return jumpToNext(findLines: true) != null;
  }

  /// Whether this [Node] has a [previous] node into its
  /// parent or the siblings of its parent
  bool get hasPossiblePrevNode {
    return jumpToPrevious(findLines: true) != null;
  }

  /// Jump to the most nearest previous [Node]
  ///
  /// - [findLines]: Determines if will be retorned [Line] or [EmbedLine] nodes instead block in jump cases
  Node? jumpToPrevious({bool findLines = false}) {
    if (previous != null) return previous;

    final Node? node =
        jumpToOptionalParent(stopAt: (Node n) => n.previous != null)?.previous;
    if (node != null && node.isBlockNode && findLines) {
      assert(
          node.lastChild == null ||
              !node.lastChild!.isBlockNode ||
              node.firstChild!.type == TableKeys.rowKey,
          'last node into ${node.shortInfo()} '
          'must be inline, but '
          'found: ${node.lastChild?.shortInfo()}');
      return node.lastChild;
    }
    return node;
  }

  /// Jump to the most nearest next [Node]
  ///
  /// - [findLines]: Determines if will be retorned [Line] or [EmbedLine] nodes instead block in jump cases
  Node? jumpToNext({bool findLines = false}) {
    if (next != null) return next;
    final Node? node =
        jumpToOptionalParent(stopAt: (Node n) => n.next != null)?.next;

    if (node != null && node.isBlockNode && findLines) {
      assert(
          node.firstChild == null ||
              !node.firstChild!.isBlockNode ||
              node.firstChild!.type == TableKeys.rowKey,
          'first node into ${node.shortInfo()} '
          'must be inline, but '
          'found: ${node.lastChild?.shortInfo()}');
      return node.firstChild;
    }
    return node;
  }

  /// Jump directly to the parent until
  /// [stopAt] returns [true] or found root [Node]
  ///
  /// if found root, return it
  Node jumpToParent({bool Function(Node)? stopAt}) {
    if (parent == null || stopAt != null && stopAt(this)) {
      return this;
    }

    return parent!.jumpToParent(stopAt: stopAt);
  }

  /// Jump directly to the parent until
  /// [stopAt] returns [true] or found root [Node]
  ///
  /// if found root, return null
  Node? jumpToOptionalParent({bool Function(Node)? stopAt}) {
    if (parent == null || isRootOwner) return null;
    if (stopAt != null && stopAt(this)) {
      return this;
    }

    return parent!.jumpToOptionalParent(stopAt: stopAt);
  }

  /// Jump to the parent that is a direct child of root [Node]
  Node? jumpToParentExceptRoot() {
    if (isRootOwner || parent == null) return null;
    if (parent!.isRootOwner) return this;
    return jumpToParent(stopAt: (Node n) => n.parent?.isRootOwner ?? false);
  }

  /// Jump each parent to get more closer at the Root node
  /// and let us know what is the current parent where we
  /// are jumping
  Node? jumpToParentExceptRootCaller(void Function(Node node) callback) {
    if (isRootOwner || parent == null) return null;
    callback(this);
    if (parent!.isRootOwner) {
      return this;
    }

    return parent?.jumpToParentExceptRootCaller(callback);
  }
}
