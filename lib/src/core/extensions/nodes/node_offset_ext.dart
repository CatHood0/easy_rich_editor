part of 'package:easy_rich_editor/src/core/api/document/nodes/node.dart';

extension NodeOffsetExt on Node {
  /// Offset in characters of this node relative to [parent] node.
  ///
  /// To get offset of this node in the Tree see [globalOffset].
  //TODO: should we just allow offset caching for non blocks
  //  since we will use paths as direct access and offsets for relative modifications
  int get offset {
    if (_offset != null) return _offset!;

    if (parent == null || isFirst) {
      return _offset ??= 0;
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

  /// Relative end Offset from its parent.
  int get endOffset {
    return offset + dataLength;
  }
}
