import 'package:easy_rich_editor/easy_rich_editor.dart';
import 'package:easy_rich_editor/src/core/api/document/changes/fragment_change_context.dart';
import 'package:flutter_test/flutter_test.dart';

import '../resources/doc_rs.dart';

void main() {
  late Node root;

  setUp(() {
    root = DocumentToNodesParser.documentParse(commonDoc);
  });

  test('split to other block node is type no correspond', () {
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

  test('insert text start of a node', () {});
  test('insert text at the end of a node', () {
    final FragmentChangeContext context = root.insert(
      1,
      '|',
    );

    expect(context.executed, isTrue);
    expect(context.changeSize, equals(1));
    expect(context.paths, equals(<int>[0]));
    expect(context.node!.deepPath, equals(<int>[0, 0]));
    expect(context.node!.toPlainText(), equals('\n|'));
  });
  test('insert text in middle of document', () {});
  test('insert text behing an embed', () {});
  test('insert text after an embed', () {});
  test('insert text at end of document', () {});
}
