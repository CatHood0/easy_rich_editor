part of 'package:easy_rich_editor/src/core/api/document/nodes/node.dart';

extension NodeTreeDumperExt on Node {
  String shortInfo() {
    if (isRootOwner) {
      return '$type(id: $id, children: $length)';
    }
    return '$type(id: $id, ${shortOffsetInfo(global: true)}, path: $deepPath)';
  }

  String shortOffsetInfo({bool global = false}) {
    return 'offset(start: ${global ? globalOffset : offset}, '
        'end: ${global ? globalEnd : endOffset})';
  }

  String dumpTreeStr({
    int tab = 0,
    List<int>? paths,
    bool applyJustIndents = false,
    int applyJustBefore = 0,
    List<int> currentPath = const <int>[0],
    bool showFullDeepPaths = false,
  }) {
    paths ??= <int>[];

    void writeSubPath(StringBuffer buffer, List<int> paths,
        {bool allowRootIndent = false}) {
      for (int subPath in paths) {
        final int effectiveSubIndent = subPath * 2;
        final String indent = !allowRootIndent
            ? subPath == 0
                ? ""
                : " " * effectiveSubIndent
            : " " * effectiveSubIndent;
        buffer.write(indent);
        if (!applyJustIndents ||
            applyJustIndents && subPath < applyJustBefore) {
          buffer.write("│");
        }
      }
    }

    final Limiter? limiter = EasyDocument.getLimiter(this);
    final List<int> nodePath = showFullDeepPaths ? deepPath : <int>[path];
    final StringBuffer buffer = StringBuffer("")
      ..write("$type(${id.substring(0, 4).trim()}"
          "-"
          "$nodePath): "
          "Offset(start: $offset, len: ${isBlockNode ? dataLength.prev.nonNegative : dataLength}, end: $endOffset) ");
    if (listEquals(currentPath, deepPath)) {
      buffer.write(" < Cursor position");
    }
    buffer.writeln("");
    final int effectiveIndent = tab * 2;

    if (limiter == null || !limiter.shouldAvoidTraverseInto(this)) {
      for (int i = 0; i < length; i++) {
        final bool isEndChil = i + 1 >= length;
        final bool isNotRootIndent = tab > 0;
        writeSubPath(buffer, paths);
        // adding indenting for the
        if (isNotRootIndent) buffer.write(" " * effectiveIndent);

        final Node child = children.elementAt(i);
        if (isEndChil) {
          // if, is the first child, and the same time
          // the last one, just add an intersection
          //
          // This just add the intersection
          // moves to a new lines and makes the same process
          if (i == 0) {
            buffer.writeln("│");
            writeSubPath(buffer, paths);
            if (isNotRootIndent) buffer.write(" " * effectiveIndent);
          }
          buffer.write("└─");
        } else {
          buffer.write("│");
        }
        // add a separation between the guide lines
        // and the node
        buffer
          ..write(" ")
          ..write(
            child.dumpTreeStr(
              tab: tab + 1,
              paths: i + 1 < length ? <int>[...paths, tab] : paths,
              applyJustIndents: i + 1 >= length,
              applyJustBefore: tab,
              currentPath: currentPath,
              showFullDeepPaths: showFullDeepPaths,
            ),
          );
      }
    }
    if (value != null) {
      // We need a way to add the other levels knowing
      // if them need a line (parent with more children
      // that the current one, must pass its level)
      writeSubPath(buffer, paths, allowRootIndent: true);
      // we add some extra indentation for the values
      buffer
        ..write(" " * (effectiveIndent + 3))
        ..write("-> ")
        ..writeln(value.toString().replaceAll(RegExp('\n'), '\\n'));
    }
    return buffer.toString();
  }
}
