import 'package:easy_rich_editor/easy_rich_editor.dart';

class NodeSelection {
  final NodePosition startPosition;
  final NodePosition endPosition;

  NodeSelection({
    required this.startPosition,
    required this.endPosition,
  });

  NodeSelection.collapsed({
    required List<int> path,
    required int offset,
    required Node node,
  })  : startPosition = NodePosition(
          path: path,
          node: node,
          position: offset,
        ),
        endPosition = NodePosition(
          path: path,
          node: node,
          position: offset,
        );

  NodeSelection.sameNode({
    required List<int> path,
    required int startOffset,
    required int endOffset,
    required Node node,
  })  : startPosition = NodePosition(
          path: path,
          node: node,
          position: startOffset,
        ),
        endPosition = NodePosition(
          path: path,
          node: node,
          position: endOffset,
        );
}
