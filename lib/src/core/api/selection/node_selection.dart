import 'package:easy_rich_editor/easy_rich_editor.dart';

class NodeSelection {
  final NodePosition startPosition;
  final NodePosition endPosition;
  final List<Node>? selectedNodes;

  NodeSelection({
    required this.startPosition,
    required this.endPosition,
    this.selectedNodes,
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
        selectedNodes = [node],
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
        selectedNodes = [node],
        endPosition = NodePosition(
          path: path,
          node: node,
          position: endOffset,
        );
}
