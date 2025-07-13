import 'package:easy_rich_editor/easy_rich_editor.dart';
import 'package:flutter_quill_delta_easy_parser/flutter_quill_delta_easy_parser.dart';
import 'package:flutter_test/flutter_test.dart';

import '../resources/doc_rs.dart';

void main() {
  test('jump to parent effectively', () {
    final Document doc = commonDoc;
    final Node root = DocumentToNodesParser.documentParse(doc);
    final Node paragraph = root.elementAt(3);
    final Node node = Node(
      type: ParagraphKeys.textKey,
      value: "Hello daddy",
      id: 'Test id',
    );

    final line = paragraph.elementAt(0);
    expect(
      line.type,
      ParagraphKeys.childrenKey,
      reason: "line must be of type 'Line'",
    );

    line.insertNode(node);
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
    final Document doc = commonDoc;
    final Node root = DocumentToNodesParser.documentParse(doc);
    final Node paragraph = root.elementAt(3);
    final Node node = Node(
      type: ParagraphKeys.textKey,
      value: "Hello daddy",
      id: 'Test id',
    );

    final line = paragraph.elementAt(0);
    expect(
      line.type,
      ParagraphKeys.childrenKey,
      reason: "line must be of type 'Line'",
    );

    line.insertNode(node);

    //print(root.dumpTreeStr(currentPath: node.deepPath));
  });
}
