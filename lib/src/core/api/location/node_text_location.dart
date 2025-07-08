import 'package:easy_rich_editor/internal.dart';
import 'package:flutter/material.dart';

/// The location of the current Node
/// and the current ranges that matches with the values of these Nodes
class NodeTextLocation {
  final NodeLocation location;
  final List<TextRange> ranges;

  NodeTextLocation({
    required this.location,
    required this.ranges,
  });
}
