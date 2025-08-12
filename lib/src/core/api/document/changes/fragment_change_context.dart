import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

import '../path/path.dart';

@internal
class FragmentChangeContext {
  final TextRange? remainingRanges;
  final bool executed;
  final FragmentPath paths;
  final int insertionSize;
  final int lastFragmentLength;

  const FragmentChangeContext({
    required this.executed,
    required this.paths,
    this.insertionSize = -1,
    this.lastFragmentLength = -1,
    this.remainingRanges,
  });

  const FragmentChangeContext.noExecuted()
      : executed = false,
        insertionSize = -1,
        lastFragmentLength = -1,
        remainingRanges = null,
        paths = const <int>[];

  FragmentChangeContext copyWith({
    TextRange? remainingRanges,
    bool? executed,
    FragmentPath? paths,
    int? insertionSize,
    int? lastFragmentLength,
  }) {
    return FragmentChangeContext(
      executed: executed ?? this.executed,
      paths: paths ?? this.paths,
      remainingRanges: remainingRanges ?? this.remainingRanges,
      insertionSize: insertionSize ?? this.insertionSize,
      lastFragmentLength: lastFragmentLength ?? this.lastFragmentLength,
    );
  }

  @override
  String toString() {
    return 'FragmentChangeContext(executed: $executed, '
        'pathChanges: $paths, '
        'size: $insertionSize, '
        'oldFragmentLength: $lastFragmentLength, '
        'remainingRanges: $remainingRanges)';
  }
}
