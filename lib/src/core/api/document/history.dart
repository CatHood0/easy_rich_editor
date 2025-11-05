import 'package:easy_rich_editor/easy_rich_editor.dart';

import '../operations/fixed_list_length.dart';

/// Re
class EasyHistory {
  static const int maxRecordOperations = 650;

  EasyHistory({
    int maxLimitOfRecords = maxRecordOperations,
  })  : undoStack = FixedListLength(
          operations: <EasyOperation>[],
          maxLength: maxLimitOfRecords,
        ),
        redoStack = FixedListLength(
          operations: <EasyOperation>[],
          maxLength: maxLimitOfRecords,
        );

  EasyHistory.fromRecords({
    required List<EasyOperation> undo,
    required List<EasyOperation> redo,
    int maxLimitOfRecords = maxRecordOperations,
  })  : undoStack = FixedListLength(
          operations: undo,
          maxLength: maxRecordOperations,
        ),
        redoStack = FixedListLength(
          operations: redo,
          maxLength: maxRecordOperations,
        );

  late final FixedListLength undoStack;
  late final FixedListLength redoStack;

  bool get hasUndo => undoStack.isNotEmpty;
  bool get hasRedo => redoStack.isNotEmpty;

  void push(
    EasyOperation op, {
    bool undo = true,
  }) =>
      undo ? undoStack.add(op) : redoStack.add(op);

  EasyOperation undo() {
    final EasyOperation head = undoStack.takeHead();
    redoStack.add(head);
    return head.invert();
  }

  EasyOperation redo() {
    final EasyOperation head = redoStack.takeHead();
    undoStack.add(head);
    return head.invert();
  }

  EasyOperation? mostRecentChange({bool undo = true}) {
    return undo ? undoStack.getRecent() : redoStack.getRecent();
  }
}
