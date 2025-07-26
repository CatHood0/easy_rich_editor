part of 'package:easy_rich_editor/src/core/api/nodes/node.dart';

extension NodeOffsetExt on Node {
  /// Offset in characters of this node relative to [parent] node.
  ///
  /// To get offset of this node in the Tree see [globalOffset].
  int get offset {
    if (_offset != null) {
      return _offset!;
    }

    if (list == null || isFirst) {
      return 0;
    }
    int offset = 0;
    for (final Node node in list!) {
      if (node == this) {
        break;
      }
      offset += node.dataLength;
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
}
