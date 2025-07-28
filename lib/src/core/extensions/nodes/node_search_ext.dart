part of 'package:easy_rich_editor/src/core/api/document/nodes/node.dart';

extension NodeSearchExt on Node {
  /// Search easily the node at the index passed using ranges
  //TODO: implement binary search
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

    if (parent!.isEmpty) return null;
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
      Node? prev;
      for (int i = path; i > 0; i--) {
        prev = parent!.children[i];
        if (targetI == i) {
          break;
        }
      }

      return prev;
    }

    if (isFront) {
      Node? next;
      for (int i = path; i < length; i++) {
        next = parent!.children[i];
        if (targetI == i) {
          break;
        }
      }

      return next;
    }

    return null;
  }

  Node elementAt(int index) => children[index];

  Node? elementAtOrNull(int index) =>
      isEmpty || index < 0 || index >= length ? null : children[index];

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
