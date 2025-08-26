import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter_quill_delta_easy_parser/flutter_quill_delta_easy_parser.dart'
    as espr;
import 'package:meta/meta.dart';

import '../../easy_rich_editor.dart';

@immutable
class DocumentToNodesParser {
  static final espr.DocumentParser _docParser =
      espr.DocumentParser(mergerBuilder: espr.BlockMergerBuilder());

  static Node markdownParse(String markdown) {
    throw UnimplementedError("Not implemented markdownParse");
  }

  static Node deltaParse(Delta delta) {
    espr.Document? doc = _docParser.parseDelta(
          delta: delta,
          returnNoSealedCopies: true,
        ) ??
        espr.Document(paragraphs: <espr.Paragraph>[]);
    return documentParse(doc);
  }

  static Node documentParse(
    espr.Document doc, {
    String Function(espr.Paragraph espr)? onDetectCustom,
  }) {
    final Node root = Node.root();
    for (espr.Paragraph pr in doc.paragraphs) {
      root.insertNode(
        pr.isEmbed
            ? Node.fromParagraphEmbed(paragraph: pr)
            : Node.fromParagraph(paragraph: pr),
      );
    }

    return root;
  }
}
