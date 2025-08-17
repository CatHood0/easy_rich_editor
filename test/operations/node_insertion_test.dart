import 'package:easy_rich_editor/easy_rich_editor.dart';
import 'package:easy_rich_editor/src/core/api/document/changes/fragment_change_context.dart';
import 'package:easy_rich_editor/src/core/extensions/object_ext.dart';
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
    expect(context.node!.deepPath, equals(<int>[0, 0]));
    expect(
      context.node!.toPlainText(),
      equals(Node.kObjectReplacementCharacter),
    );
  });

  test('insert text at start of a embed', () {
    expect(root, isNotNull);
    final FragmentChangeContext context = root!.insert(
      2,
      '|',
    );

    expect(context.executed, isTrue);
    expect(context.changeSize, equals(1));
    expect(context.paths, equals(<int>[0]));
    expect(context.node!.deepPath, equals(<int>[1, 0]));
    expect(context.node!.toPlainText(), equals('|'));
  });

  test('split node in middle when required', () {
    expect(root, isNotNull);
    final Node? line = root!.queryPath(<int>[2, 1]);
    expect(line, isNotNull);
    expect(line!.type, equals(ParagraphKeys.lineKey));
    expect(line.parent!.type, equals(ParagraphKeys.key));
    expect(line.text, equals('use it '));
    final Node? endLineSibling = line.next;
    expect(endLineSibling, isNotNull);
    expect(endLineSibling!.type, equals(ParagraphKeys.lineKey));
    expect(endLineSibling.text,
        equals('to take as an example how work this visualizer (1). '));
    final Node? block = root!.queryPath(<int>[2]);
    expect(block, isNotNull);
    expect(block!.length, equals(3));
    expect(line.parent, block);
    expect(endLineSibling.parent, block);
    final Map<String, dynamic> obj = <String, dynamic>{
      'image': 'path/to/image'
    };
    final FragmentChangeContext context = line.insert(
      3,
      obj,
    );
    // was splitted from the offset passed
    expect(line.nsText, equals('use'));
    expect(context.executed, isTrue);
    expect(context.changeSize, equals(164));
    expect(context.node, equals(block));
    expect(block.length, equals(2));
    final Node? embedLeft = root!.queryPath(<int>[3]);
    expect(embedLeft, isNotNull);
    final NodeCursorPosLocation location =
        embedLeft!.queryPosition(1, inclusive: true);
    expect(location.node, isNotNull);
    expect(location.found, isTrue);
    expect(location.fragmentIndex, equals(0));
    expect(
      location.node!.value.castToFragments()[location.fragmentIndex].data,
      equals(obj),
    );
    final Node? rightSplitted = root!.queryPath(<int>[4]);
    expect(rightSplitted, isNotNull);
    expect(rightSplitted!.length, equals(2));
    // and here is where end the part of the line splitted 
    expect(
      rightSplitted.first.value.castToFragments().first.data,
      equals(" it "),
    );
    expect(line.parent, block);
    expect(endLineSibling.parent, isNot(equals(block)));
    expect(endLineSibling.parent, equals(rightSplitted));
  });

  test('insert text at start of a node', () {
    expect(root, isNotNull);
    final FragmentChangeContext context = root!.insert(
      0,
      '|',
    );

    expect(context.executed, isTrue);
    expect(context.changeSize, equals(1));
    expect(context.paths, equals(<int>[0]));
    expect(context.node!.deepPath, equals(<int>[0, 0]));
    expect(context.node!.toPlainText(), equals('|\n'));
  });
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
