import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter_quill_delta_easy_parser/flutter_quill_delta_easy_parser.dart';
import 'package:easy_rich_editor/easy_rich_editor.dart';
import 'package:meta/meta.dart';

@immutable
class DocumentToNodesParser {
  static final DocumentParser _docParser =
      DocumentParser(mergerBuilder: BlockMergerBuilder());

  static Node markdownParse(String markdown) {
    throw UnimplementedError("Not implemented markdownParse");
  }

  static Node deltaParse(Delta delta) {
    Document? doc = _docParser.parseDelta(
          delta: delta,
          returnNoSealedCopies: true,
        ) ??
        Document(paragraphs: <Paragraph>[]);
    return documentParse(doc);
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
