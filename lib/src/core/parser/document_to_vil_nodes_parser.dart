import 'package:flutter_quill_delta_easy_parser/flutter_quill_delta_easy_parser.dart';
import 'package:easy_rich_editor/internal.dart';
import 'package:meta/meta.dart';

@internal
@immutable
class DocumentToVilNodesParser {
  static List<Node> parse(
    Document doc, {
    String Function(Paragraph pr)? onDetectCustom,
  }) {
    final List<Node> nodes = <Node>[];
    for (Paragraph pr in doc.paragraphs) {
      nodes.add(Node.fromParagraph(paragraph: pr));
    }
    return <Node>[...nodes];
  }

  static Node parseForRoot(
    Document doc, {
    String Function(Paragraph pr)? onDetectCustom,
  }) {
    final root = Node(
      id: Node.rootId,
      type: Node.rootId,
      value: null,
      children: [],
    );
    for (Paragraph pr in doc.paragraphs) {
      //TODO: add parsing for specific nodes here
      root.insertNode(Node.fromParagraph(paragraph: pr));
    }

    return root;
  }
}
