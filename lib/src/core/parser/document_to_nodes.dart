import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter_quill_delta_easy_parser/flutter_quill_delta_easy_parser.dart';
import 'package:easy_rich_editor/internal.dart';
import 'package:meta/meta.dart';

@internal
@immutable
class DocumentToNodesParser {
  static Node markdownParse(String markdown) {
    throw UnimplementedError("Not implemented markdownParse");
  }

  static Node deltaParse(Delta delta) {
    throw UnimplementedError("Not implemented deltaParse");
  }

  static Node documentParse(
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
      root.insertNode(
        pr.isEmbed
            ? Node.fromParagraphEmbed(paragraph: pr)
            : Node.fromParagraph(paragraph: pr),
      );
    }

    return root;
  }
}
