import 'package:easy_rich_editor/easy_rich_editor.dart';
import 'package:easy_rich_editor/src/core/api/document/changes/fragment_change_context.dart';
import 'package:flutter_test/flutter_test.dart';

import '../resources/doc_rs.dart';

void main() {
  final Node root = DocumentToNodesParser.documentParse(commonDoc);
  test('insertText', () {
    final FragmentChangeContext context = root.insert(
      1,
      '|',
    );

    print(root.dumpTreeStr(currentPath: [2, 0]));
  });
  test('insertNode', () {});
}
