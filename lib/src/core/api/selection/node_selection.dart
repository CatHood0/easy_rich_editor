import 'package:easy_rich_editor/easy_rich_editor.dart';
import 'package:easy_rich_editor/src/core/api/document/path/path.dart';

class NodeSelection {
  final NodePosition start;
  final NodePosition end;
  final List<Node>? selectedNodes;

  NodeSelection({
    required this.start,
    required this.end,
    this.selectedNodes,
  });

  NodeSelection.collapsed({
    required List<int> path,
    required int offset,
    required Node node,
  })  : start = NodePosition(
          path: path,
          node: node,
          position: offset,
        ),
        selectedNodes = [node],
        end = NodePosition(
          path: path,
          node: node,
          position: offset,
        );

  NodeSelection.sameNode({
    required List<int> path,
    required int startOffset,
    required int endOffset,
    required Node node,
  })  : start = NodePosition(
          path: path,
          node: node,
          position: startOffset,
        ),
        selectedNodes = [node],
        end = NodePosition(
          path: path,
          node: node,
          position: endOffset,
        );

  /// Returns a Boolean indicating whether the selection's start and end points
  /// are at the same position.
  bool get isCollapsed => start == end;

  /// Returns a Boolean indicating whether the selection's start and end points
  /// are at the same path.
  bool get isSingle => start.path.equals(end.path);

  /// Returns a Boolean indicating whether the selection is forward.
  bool get isForward =>
      (start.path > end.path) || (isSingle && start.position > end.position);

  /// Returns a Boolean indicating whether the selection is backward.
  bool get isBackward =>
      (start.path < end.path) || (isSingle && start.position < end.position);

  /// Returns a normalized selection that direction is forward.
  NodeSelection get normalized => isBackward ? this : reversed.copyWith();

  /// Returns a reversed selection.
  NodeSelection get reversed => copyWith(start: end, end: start);

  /// Returns the offset in the starting position under the normalized selection.
  int get startIndex => normalized.start.position;

  /// Returns the offset in the ending position under the normalized selection.
  int get endIndex => normalized.end.position;

  int get length => endIndex - startIndex;

  NodeSelection copyWith({
    NodePosition? start,
    NodePosition? end,
    List<Node>? selectedNodes,
  }) {
    return NodeSelection(
      start: start ?? this.start,
      end: end ?? this.end,
      selectedNodes: selectedNodes ?? this.selectedNodes,
    );
  }
}
