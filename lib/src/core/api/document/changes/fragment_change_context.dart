import 'package:flutter/material.dart';
import '../../../../../easy_rich_editor.dart';
import '../path/path.dart';

class FragmentChangeContext {
  final TextRange? remainingRanges;
  final bool executed;
  final FragmentPath paths;
  final int changeSize;
  final int lastFragmentLength;
  final Node? node;

  const FragmentChangeContext({
    required this.executed,
    required this.paths,
    required this.node,
    this.changeSize = -1,
    this.lastFragmentLength = -1,
    this.remainingRanges,
  });

  const FragmentChangeContext.noExecuted()
      : executed = false,
        changeSize = -1,
        node = null,
        lastFragmentLength = -1,
        remainingRanges = null,
        paths = const <int>[];

  FragmentChangeContext copyWith({
    TextRange? remainingRanges,
    bool? executed,
    FragmentPath? paths,
    int? changeSize,
    int? lastFragmentLength,
    Node? node,
  }) {
    return FragmentChangeContext(
      executed: executed ?? this.executed,
      paths: paths ?? this.paths,
      node: node ?? this.node,
      remainingRanges: remainingRanges ?? this.remainingRanges,
      changeSize: changeSize ?? this.changeSize,
      lastFragmentLength: lastFragmentLength ?? this.lastFragmentLength,
    );
  }

  @override
  String toString() {
    return 'FragmentChangeContext(executed: $executed, '
        'pathChanges: $paths, '
        'size: $changeSize, '
        'node: $node, '
        'oldFragmentLength: $lastFragmentLength, '
        'remainingRanges: $remainingRanges)';
  }
}
