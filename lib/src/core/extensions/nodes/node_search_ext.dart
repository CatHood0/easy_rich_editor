part of 'package:easy_rich_editor/src/core/api/document/nodes/node.dart';

extension NodeSearchExt on Node {
  /// Search easily the node at the index passed using ranges
  Node? fastSearch(int targetI, {bool into = true, int? endRangeLimit}) {
    RangeError.checkNotNegative(targetI);
    if (into) {
      if (targetI >= length) {
        throw RangeError.range(
          targetI,
          0,
          length,
          'InvalidNodeRange',
        );
      }
      endRangeLimit ??= 15;
      final int endRange = (length - endRangeLimit).clamp(0, length);

      if (targetI >= endRange) {
        return lastChild?.fastSearch(targetI, into: false);
      }
      return firstChild?.fastSearch(targetI, into: false);
    }

    if (targetI == path) return this;

    if (targetI >= parent!.length) {
      throw RangeError.range(
        targetI,
        0,
        parent!.length,
        'InvalidNodeRange',
      );
    }

    final bool isBack = targetI < path;
    final bool isFront = targetI > path;
    if (isBack) {
      Node? prev = previous;
      while (prev!.path > targetI) {
        prev = prev.previous;
        if (prev == null) break;
      }

      if (prev?.path == targetI) return prev;
    }

    if (isFront) {
      Node? nextN = next;
      while (nextN!.path < targetI) {
        nextN = nextN.next;
        if (nextN == null) break;
      }

      if (nextN?.path == targetI) return nextN;
    }

    return null;
  }

  Node elementAt(int index) => fastSearch(index)!;

  Node? elementAtOrNull(int index) => fastSearch(index);

  bool contains(String id) => _fastIndexTreePart[id] != null;

  /// Returns `true` if this node contains character at specified [offset] in
  /// the document.
  bool containsOffset(int offset) {
    final int o = globalOffset;
    return o <= offset && offset < o + length;
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
}
