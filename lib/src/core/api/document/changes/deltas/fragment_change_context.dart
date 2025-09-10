import 'package:flutter/material.dart';

import '../../../../../../easy_rich_editor.dart';

enum NoExecutionReason {
  noSatifyConditions,
  invalidEnd,
  invalidStart,
  noElement,
}

class FragmentChangeContext {
  final bool executed;
  final int changeSize;
  final Node? node;
  final NoExecutionReason? reason;

  const FragmentChangeContext({
    required this.executed,
    required this.node,
    this.changeSize = -1,
    this.reason,
  });

  const FragmentChangeContext.noExecuted([NoExecutionReason? reason])
      : executed = false,
        changeSize = -1,
        node = null,
        reason = reason ?? NoExecutionReason.noSatifyConditions;

  FragmentChangeContext copyWith({
    bool? executed,
    int? changeSize,
    Node? node,
  }) {
    return FragmentChangeContext(
      executed: executed ?? this.executed,
      node: node ?? this.node,
      changeSize: changeSize ?? this.changeSize,
    );
  }

  @override
  String toString() {
    return 'FragmentChangeContext(executed: $executed, '
        'size: $changeSize, '
        'node: $node, '
        'reason: $reason)';
  }
}

class MultipleFragmentChangeContext extends FragmentChangeContext {
  final List<FragmentChangeContext> changes;
  MultipleFragmentChangeContext({
    required super.executed,
    required this.changes,
    super.node,
    super.changeSize,
  });

  @override
  MultipleFragmentChangeContext copyWith({
    TextRange? remainingRanges,
    bool? executed,
    List<FragmentChangeContext>? changes,
    int? changeSize,
    Node? node,
  }) {
    return MultipleFragmentChangeContext(
      executed: executed ?? this.executed,
      changes: changes ?? this.changes,
      node: node ?? this.node,
      changeSize: changeSize ?? this.changeSize,
    );
  }
}
