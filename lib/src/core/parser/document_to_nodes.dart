import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter_quill_delta_easy_parser/flutter_quill_delta_easy_parser.dart'
    as pr;
import 'package:easy_rich_editor/easy_rich_editor.dart';
import 'package:meta/meta.dart';

@immutable
class DocumentToNodesParser {
  static final pr.DocumentParser _docParser =
      pr.DocumentParser(mergerBuilder: pr.BlockMergerBuilder());

  static Node markdownParse(String markdown) {
    throw UnimplementedError("Not implemented markdownParse");
  }

  static Node deltaParse(Delta delta) {
    pr.Document? doc = _docParser.parseDelta(
          delta: delta,
          returnNoSealedCopies: true,
        ) ??
        pr.Document(paragraphs: <pr.Paragraph>[]);
    return documentParse(doc);
  }

  static Node documentParse(
    pr.Document doc, {
    String Function(pr.Paragraph pr)? onDetectCustom,
  }) {
    final root = Node(
      id: Node.rootId,
      type: Node.rootId,
      value: null,
      children: [],
    );
    for (pr.Paragraph pr in doc.paragraphs) {
      root.insertNode(
        pr.isEmbed
            ? Node.fromParagraphEmbed(paragraph: pr)
            : Node.fromParagraph(paragraph: pr),
      );
    }

    return root;
  }
}
