import '../diff.dart';
import 'package:flutter/material.dart';

abstract class DiffAlgorithm {
  static const DefaultDiffAlgorithm defaultAlg = DefaultDiffAlgorithm(); 
  const DiffAlgorithm();

  TextDiffer? diff(
    String text,
    String old,
    TextRange changeRange,
  );
}
