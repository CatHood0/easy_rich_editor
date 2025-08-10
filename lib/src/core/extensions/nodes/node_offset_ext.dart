part of 'package:easy_rich_editor/src/core/api/document/nodes/node.dart';

extension NodeOffsetExt on Node {
  /// Offset in characters of this node relative to [parent] node.
  ///
  /// To get offset of this node in the Tree see [globalOffset].
  int get offset {
    // when a [Node] is a non block (usually, we pass this info into [metadata] property),
    // this means that it contains a [List<TextFragment>] or direct values
    // that are used by the editor
    //
    // so, we just prefer computing every time the offset of these
    // nodes, to just invalidating the block offsets (avoid double invalidation checking:
    // children and block sibling invalidations)
    if (!isBlockNode) {
      if (_offset != null) _offset = null;
      if (parent == null || isFirst) return 0;
      final List<Node> siblings = parent!.children;
      int offset = 0;
      for (int i = 0; i < siblings.length; i++) {
        if (siblings[i] == this) break;
        offset += siblings[i].dataLength;
      }
      return offset;
    }

    if (_offset != null) return _offset!;

    if (parent == null || isFirst) {
      _offset = 0;
      return _offset!;
    }

    final List<Node> siblings = parent!.children;
    int offset = 0;
    for (int i = 0; i < siblings.length; i++) {
      if (siblings[i] == this) break;
      offset += siblings[i].dataLength;
    }

    _offset = offset;
    return _offset!;
  }

  /// Offset in characters of this node in the Tree.
  int get globalOffset {
    if (parent == null) {
      return offset;
    }
    final int parentOffset = !parent!.isRootOwner ? parent!.globalOffset : 0;
    return parentOffset + offset;
  }

  /// Start Offset in characters of this node in the Tree.
  int get globalStart {
    return globalOffset;
  }

  /// End Offset in characters of this node in the Tree.
  int get globalEnd {
    return globalStart + dataLength;
  }

  bool containsSelection(NodeSelection selection) {
    return false;
  }
}
