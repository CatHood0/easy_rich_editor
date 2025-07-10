import 'package:easy_rich_editor/easy_rich_editor.dart';

class TreeIndexerPayload {
  final Node root;
  final Map<String, int> curIndexTree;
  final int loadAfter;
  final int newValueAfter;

  TreeIndexerPayload({
    required this.root,
    this.loadAfter = -1,
    this.newValueAfter = -1,
    this.curIndexTree = const <String, int>{},
  });
}

class TreeIndexerResult {
  final Map<String, int> indexes;

  TreeIndexerResult(this.indexes);
}
