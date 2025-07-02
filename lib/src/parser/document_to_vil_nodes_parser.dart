import 'package:flutter_quill_delta_easy_parser/flutter_quill_delta_easy_parser.dart';
import 'package:flutter_quill_delta_easy_parser_visualizer/src/builders/header/header_keys.dart';
import 'package:flutter_quill_delta_easy_parser_visualizer/src/nodes/node.dart';
import 'package:meta/meta.dart';

@internal
@immutable
class DocumentToVilNodesParser {
  final Map<String, String> _blockTypes = {
    "header": HeaderKeys.key,
    "list": "block",
    "code-block": "block",
    "style": "block",
    "blockquote": "block",
  };

  static List<EasyVilNode> parse(
    Document doc, {
    String Function(Paragraph pr)? onDetectCustom,
  }) {
    final List<EasyVilNode> nodes = <EasyVilNode>[];
    for (Paragraph pr in doc.paragraphs) {
      nodes.add(
        EasyVilNode.fromParagraph(
          paragraph: pr,
        ),
      );
    }
    return <EasyVilNode>[...nodes];
  }

  static EasyVilNode parseForRoot(
    Document doc, {
    String Function(Paragraph pr)? onDetectCustom,
  }) {
    final root = EasyVilNode(
      id: 'root',
      type: 'root',
      value: null,
      children: [],
    );
    for (Paragraph pr in doc.paragraphs) {
      root.insertNode(
        EasyVilNode.fromParagraph(
          paragraph: pr,
        ),
      );
    }

    return root;
  }
}
