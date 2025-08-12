import 'package:easy_rich_editor/easy_rich_editor.dart';
import 'package:flutter_quill_delta_easy_parser/flutter_quill_delta_easy_parser.dart' as pr;
import 'package:flutter_test/flutter_test.dart';

import '../resources/doc_rs.dart';

void main() {
  test('jump to parent effectively', () {
    final pr.Document doc = commonDoc;
    final Node root = DocumentToNodesParser.documentParse(doc);
    final Node paragraph = root.elementAt(3);
    final Node node = Node(
      type: ParagraphKeys.lineKey,
      value: [
        pr.TextFragment(data: "This is my example text bitch. "),
        pr.TextFragment(data: "So, i want to know "),
        pr.TextFragment(data: "why (2)", attributes: {'bold': true}),
      ],
      id: 'Test id',
      canModifyChildrenLength: false,
    );

    paragraph.insertNode(node, path: 0, after: true);
    final rootNode = node.jumpToParent(stopAt: (node) {
      // if the parent of the cur parent, is null
      // means that we are currently at the root
      if (node.parent?.parent == null) {
        return true;
      }
      return false;
    });

    expect(rootNode.id, paragraph.id);
    expect(rootNode, paragraph);
  });

  test('just a simple text to know if the tree works as expected', () {
    final pr.Document doc = commonDoc;
    final Node root = DocumentToNodesParser.documentParse(doc);
    final Node paragraph = root.elementAt(3);
    final Node node = Node(
      type: ParagraphKeys.lineKey,
      value: [
        pr.TextFragment(data: "This is my example text bitch. "),
        pr.TextFragment(data: "So, i want to know "),
        pr.TextFragment(data: "why", attributes: {'bold': true}),
      ],
      id: 'Test id',
      canModifyChildrenLength: false,
    );

    paragraph.insertNode(node, path: 0, after: false);
  });
}
