import 'package:easy_rich_editor/internal.dart';

class TreeIndexerPayload {
  final Node root;
  final Map<String, Node> curIndexTree;

  TreeIndexerPayload({
    required this.root,
    this.curIndexTree = const <String, Node>{},
  });
}

class TreeIndexerResult {
  final Map<String, Node> indexes;

  TreeIndexerResult(this.indexes);
}
