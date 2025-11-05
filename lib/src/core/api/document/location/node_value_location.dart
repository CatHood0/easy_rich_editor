import 'package:easy_rich_editor/easy_rich_editor.dart';
import 'package:flutter/material.dart';

/// The location of the current Node
/// and the current ranges that matches with the values of these Nodes
///
/// Tipically this class is used when you use the search option
/// for the editor (it's like searching any type of text)
class NodeValueLocation {
  final NodeLocation location;
  final List<TextRange> ranges;

  NodeValueLocation({
    required this.location,
    required this.ranges,
  });

  @override
  String toString() {
    return 'NodeValueLocation(ranges: $ranges, location: $location)';
  }
}
