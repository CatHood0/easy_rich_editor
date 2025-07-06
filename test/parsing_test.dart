import 'package:flutter/widgets.dart';
import 'package:flutter_quill_delta_easy_parser/flutter_quill_delta_easy_parser.dart';
import 'package:easy_rich_editor/easy_rich_editor.dart';
import 'package:easy_rich_editor/internal.dart';
import 'package:flutter_test/flutter_test.dart';

import 'resources/doc_rs.dart';

void main() {
  test('', () {
    final Document doc = commonDoc;
    final Node root = DocumentToVilNodesParser.parseForRoot(doc);
    final Node paragraph = root.firstChild!;

    paragraph.firstChild!.insertNode(
      Node(
        type: ParagraphKeys.textKey,
        value: "Hello daddy",
        id: 'Test id',
      ),
    );

    debugPrint(root.dumpTreeStr());
  });
}
