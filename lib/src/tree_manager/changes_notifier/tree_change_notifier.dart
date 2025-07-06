import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:easy_rich_editor/internal.dart';

class TreeChangeNotifier extends ValueNotifier<List<Node>> {
  final List<Node> changedNodes;

  TreeChangeNotifier(this.changedNodes) : super(changedNodes);
}
