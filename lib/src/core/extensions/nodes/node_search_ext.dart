part of 'package:easy_rich_editor/src/core/api/document/nodes/node.dart';

extension NodeSearchExt on Node {
  /// Search easily the node at the index passed using ranges
  //TODO: implement binary search
  Node? fastSearch(int index) {
    throw UnimplementedError("fastSearch is not implemented yet");
  }

  Node elementAt(int index) => children[index];

  Node? elementAtOrNull(int index) =>
      isEmpty || index < 0 || index >= length ? null : children[index];

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

  bool inSelection(NodeSelection selection) {
    if (selection.start.path <= selection.end.path) {
      return selection.start.path <= deepPath && deepPath <= selection.end.path;
    } else {
      return selection.end.path <= deepPath && deepPath <= selection.start.path;
    }
  }

  Node? findById(String id, {bool deep = true}) {
    if (this.id == id) return this;
    if (isEmpty) return null;

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

  Node jumpToParent({bool Function(Node)? stopAt}) {
    if (parent == null || stopAt != null && stopAt(this)) {
      return this;
    }

    return parent!.jumpToParent(stopAt: stopAt);
  }

  Node? jumpToParentExceptRoot() {
    if (isRootOwner || parent == null) return null;
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

  /// Queries the child [Node] at [offset] in this [Node].
  ///
  /// The result may contain the found node or `null` if no node is found
  /// at specified offset.
  ///
  /// [NodeCursorPosLocation.fragmentIndex] is set to relative fragment index
  /// within returned child node
  ///
  /// [NodeCursorPosLocation.fragmentOffset] is set to relative offset into the fragments
  /// within returned child node which points at the same character position in the document
  ///
  /// [NodeCursorPosLocation.locationOffset] is set to relative offset within returned child node
  /// which points at the same character position in the document as the
  /// original [offset]
  NodeCursorPosLocation queryPositionLinear(
    int cursorPos, {
    bool includeLastNode = false,
  }) {
    if (cursorPos < 0 || cursorPos > dataLength) {
      return NodeCursorPosLocation.notFound();
    }

    for (final Node node in children) {
      final int len = node.dataLength;
      // at this point, the cursor can be used
      // as a local position in the node, instead
      // a global one
      if (cursorPos < len ||
          (includeLastNode && cursorPos == len && node.isLast)) {
        // this means that we are in a `Node` of type `Line` or `EmbedLine`
        if (node.hasDefinedValue) {
          final List<TextFragment> frags = node.value!.castToFragments();
          int fragOffset = 0;
          for (int i = 0; i < frags.length; i++) {
            final TextFragment frag = frags[i];
            final int fragmentLength =
                frag.data is String ? frag.data.castString().length : 1;

            final int effectivePosition = fragOffset + fragmentLength;
            // if the cursor is in this exact fragment
            if (cursorPos < effectivePosition) {
              return NodeCursorPosLocation(
                location: NodeLocation(
                  path: <int>[...node.deepPath],
                  node: node,
                ),
                fragmentIndex: i,
                fragmentOffset: cursorPos - fragOffset,
                locationOffset: cursorPos,
              );
            }

            fragOffset += fragmentLength;
          }
        }

        return NodeCursorPosLocation(
          location: NodeLocation(path: <int>[...node.deepPath], node: node),
          fragmentIndex: -1,
          fragmentOffset: -1,
          locationOffset: cursorPos,
        );
      }
      cursorPos -= len;
    }

    return NodeCursorPosLocation.notFound();
  }

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
      return NodeCursorPosLocation.notFound();
    }

    if (hasDefinedValue) {
      return queryFragments(cursorPos, inclusive: true);
    }

    int low = 0;
    int high = length.prev.nonNegative;
    Node? foundNode;
    int localOffset = 0;
    while (low <= high) {
      final int mid = (low + high) ~/ 2;
      final Node node = children[mid];

      if (node.containsOffset(
        cursorPos,
        local: true,
        inclusive: !node.isBlockNode,
      )) {
        foundNode = node;
        localOffset = cursorPos - node.offset;
        break;
      } else if (node.isBehind(cursorPos)) {
        high = mid - 1;
      } else {
        low = mid + 1;
      }
    }

    if (inclusive && cursorPos == dataLength && isNotEmpty) {
      final Node lastNode = children.last;
      return NodeCursorPosLocation(
        location:
            NodeLocation(path: <int>[...lastNode.deepPath], node: lastNode),
        fragmentIndex: -1,
        fragmentOffset: -1,
        locationOffset: lastNode.dataLength,
      );
    }

    if (foundNode == null) {
      return NodeCursorPosLocation.notFound();
    }

    return foundNode.queryFragments(localOffset, inclusive: inclusive);
  }

  NodeCursorPosLocation queryFragments(
    int cursorPos, {
    bool inclusive = false,
  }) {
    if (cursorPos < 0 || cursorPos > dataLength) {
      return NodeCursorPosLocation.notFound();
    }

    if (hasDefinedValue) {
      final List<TextFragment> frags = value!.castToFragments();
      int fragOffset = 0;

      for (int i = 0; i < frags.length; i++) {
        final TextFragment frag = frags[i];
        final int fragmentLength = frag.length;

        final int fragEnd = fragOffset + fragmentLength;
        // if the cursor is in this exact fragment
        if (cursorPos < fragEnd || inclusive && cursorPos <= fragEnd) {
          return NodeCursorPosLocation(
            location: NodeLocation(
              path: <int>[...deepPath],
              node: this,
            ),
            fragmentIndex: i,
            fragmentOffset: cursorPos - fragOffset,
            locationOffset: cursorPos,
            jumpOffset: fragOffset,
          );
        }

        fragOffset += fragmentLength;
      }
    }

    return NodeCursorPosLocation(
      location: NodeLocation(
        path: <int>[...deepPath],
        node: this,
      ),
      locationOffset: cursorPos,
    );
  }
}
