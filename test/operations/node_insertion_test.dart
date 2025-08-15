import 'package:easy_rich_editor/easy_rich_editor.dart';
import 'package:easy_rich_editor/src/core/api/document/changes/fragment_change_context.dart';
import 'package:flutter_test/flutter_test.dart';

import '../resources/doc_rs.dart';

void main() {
  final Node root = DocumentToNodesParser.documentParse(commonDoc);
  test('insertText', () {
    final FragmentChangeContext context = root.insert(
      0,
      '|',
    );

    expect(context.executed, isTrue);
    expect(context.insertionSize, equals(1));
    expect(context.paths, equals(<int>[0]));
    expect(context.node!.deepPath, equals(<int>[0, 0]));
  });
  test('insertNode', () {});
}
