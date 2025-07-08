import 'package:easy_rich_editor/internal.dart';

class TreeIndexerPayload {
  final Node root;

  TreeIndexerPayload({
    required this.root,
  });
}

class TreeIndexerResult {
  final Map<String, Node> indexes;

  TreeIndexerResult(this.indexes);
}
