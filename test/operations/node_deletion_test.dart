import 'package:easy_rich_editor/easy_rich_editor.dart';
import 'package:easy_rich_editor/src/core/api/document/changes/fragment_change_context.dart';
import 'package:flutter_test/flutter_test.dart';

import '../resources/doc_rs.dart';

void main() {
  late Node root;

  setUp(() {
    root = DocumentToNodesParser.documentParse(commonDoc);
  });

  test('Delete all the text of a node', () {
    final FragmentChangeContext context = root.delete(
      0,
      1,
    );

    expect(context.executed, isTrue);
    expect(context.changeSize, equals(1));
    expect(context.paths, equals(<int>[0]));
    expect(context.node!.deepPath, equals(<int>[0, 0]));
    expect(context.node!.toPlainText(), equals(''));
  });

  test('Delete a character in middle of text', () {});
  test('Delete two nodes that are being selected', () {});
  test('Delete embed', () {});
  test('Delete entire document content', () {});
}
