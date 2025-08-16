import 'package:easy_rich_editor/easy_rich_editor.dart';
import 'package:easy_rich_editor/src/core/api/document/changes/fragment_change_context.dart';
import 'package:flutter_test/flutter_test.dart';

import '../resources/doc_rs.dart';

void main() {
  Node? root;

  setUp(() {
    root = DocumentToNodesParser.documentParse(commonDoc);
  });

  test('split to other block node is type no correspond', () {
    expect(root, isNotNull);
    final FragmentChangeContext context = root!.insert(
      0,
      <String, dynamic>{'image': 'path/to/image'},
    );

    expect(context.executed, isTrue);
    expect(context.changeSize, equals(1));
    expect(context.paths, equals(<int>[0]));
    // must split the current node to a next one with the correct type
    // and the context should work
    expect(context.node!.deepPath, equals(<int>[1, 0]));
    expect(
      context.node!.toPlainText(),
      equals(Node.kObjectReplacementCharacter),
    );
  });

  test('try to insert embed in a line node', () {
    expect(root, isNotNull);
    final Node? line = root!.queryPath(<int>[2, 1]);
    expect(line, isNotNull);
    expect(line!.type, equals(ParagraphKeys.lineKey));
    expect(line.parent!.type, equals(ParagraphKeys.key));
    expect(line.text, equals('use it '));
    final FragmentChangeContext context = line.insert(
      5,
      <String, dynamic>{'image': 'path/to/image'},
    );

    expect(context.executed, isTrue);
    expect(context.changeSize, equals(1));
    expect(context.paths, equals(<int>[0]));
    // must split the current node to a next one with the correct type
    // and the context should work
    expect(context.node!.deepPath, equals(<int>[3, 0]));
    expect(
      context.node!.toPlainText(),
      equals(Node.kObjectReplacementCharacter),
    );
  });

  test('insert text start of a node', () {});
  test('insert text at the end of a node', () {
    expect(root, isNotNull);
    final FragmentChangeContext context = root!.insert(
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
