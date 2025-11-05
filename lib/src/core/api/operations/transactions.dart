import 'dart:collection';

import 'package:easy_rich_editor/easy_rich_editor.dart';

class Transactions {
  final Queue<EasyOperation> operations;

  // the selection before the change
  NodeSelection? before;
  // the selection after the change
  NodeSelection? after;

  Transactions({
    required this.operations,
  });

  void apply(EasyDocument document) {}
}
