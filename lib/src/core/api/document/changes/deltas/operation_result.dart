import 'package:flutter/material.dart';

import '../../../../../../easy_rich_editor.dart';

enum NoExecutionReason {
  noSatifyConditions,
  invalidEnd,
  invalidStart,
  noElement,
}

class OperationResult {
  final bool executed;
  final int changeSize;
  final Node? node;
  final NoExecutionReason? reason;

  const OperationResult({
    required this.executed,
    required this.node,
    this.changeSize = -1,
    this.reason,
  });

  const OperationResult.noExecuted([NoExecutionReason? reason])
      : executed = false,
        changeSize = -1,
        node = null,
        reason = reason ?? NoExecutionReason.noSatifyConditions;

  OperationResult copyWith({
    bool? executed,
    int? changeSize,
    Node? node,
  }) {
    return OperationResult(
      executed: executed ?? this.executed,
      node: node ?? this.node,
      changeSize: changeSize ?? this.changeSize,
    );
  }

  @override
  String toString() {
    return 'OperationResult(executed: $executed, '
        'size: $changeSize, '
        'node: ${node?.shortInfo()}, '
        'reason: $reason)';
  }
}

class MultipleOpResults extends OperationResult {
  final List<OperationResult> changes;
  MultipleOpResults({
    required super.executed,
    required this.changes,
    super.node,
    super.changeSize,
  });

  @override
  MultipleOpResults copyWith({
    TextRange? remainingRanges,
    bool? executed,
    List<OperationResult>? changes,
    int? changeSize,
    Node? node,
  }) {
    return MultipleOpResults(
      executed: executed ?? this.executed,
      changes: changes ?? this.changes,
      node: node ?? this.node,
      changeSize: changeSize ?? this.changeSize,
    );
  }

  @override
  String toString() {
    return 'OperationResult(executed: $executed, '
        'size: $changeSize, '
        'node: ${node?.shortInfo()}, '
        'reason: $reason, '
        'changes: $changes)';
  }
}
