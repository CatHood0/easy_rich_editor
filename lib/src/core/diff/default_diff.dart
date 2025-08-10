import 'package:flutter/material.dart';
import 'diff.dart';

class DefaultDiffAlgorithm extends DiffAlgorithm {
  const DefaultDiffAlgorithm();

  @override
  TextDiffer? diff(String text, String old, TextRange changeRange) {
    return null;
  }

  int createPrefixLen() {
    return 0;
  }
  int createSuffixLen() {
    return 0;
  }
}
