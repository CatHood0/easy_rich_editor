import 'package:easy_rich_editor/easy_rich_editor.dart';
import 'package:easy_rich_editor/src/core/extensions/object_ext.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../resources/doc_rs.dart';

void main() {
  Node? root;

  setUp(() {
    root = DocumentToNodesParser.documentParse(commonDoc);
  });

  test('insert embed at the left of paragraph block node', () {
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

  test('insert embed at the right of paragraph block node', () {
    expect(root, isNotNull);
    final FragmentChangeContext context = root!.insert(
      2,
      <String, dynamic>{'image': 'path/to/image'},
    );

    expect(context.executed, isTrue);
    expect(context.changeSize, equals(1));
    expect(context.paths, equals(<int>[0]));
    // must split the current node to a next one with the correct type
    // and the context should work
    expect(context.node!.deepPath, equals(<int>[2, 0]));
    expect(context.node!.text, equals(Node.kObjectReplacementCharacter));
  });

  test('insert text at start of an embed', () {
    expect(root, isNotNull);
    final FragmentChangeContext context = root!.insert(
      1,
      '|',
    );

    expect(context.executed, isTrue);
    expect(context.changeSize, equals(1));
    expect(context.paths, equals(<int>[0]));
    expect(context.node!.deepPath, equals(<int>[1, 0]));
    expect(context.node!.text, equals('|'));
  });

  test(
      'split node at specified offset when '
      'required (by non supported type detection)', () {
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
      4,
      obj,
    );
    expect(context, isA<MultipleFragmentChangeContext>());
    expect(context.cast<MultipleFragmentChangeContext>().changes.first.node,
        equals(line));
    expect(block.length, equals(2));
    expect(line.next, isNull);
    final Node? embedLeft = root!.queryPath(<int>[3]);
    expect(embedLeft, isNotNull);
    final NodeCursorPosLocation location =
        embedLeft!.queryPosition(1, inclusive: true);
    final Node? rightSplitted = root!.queryPath(<int>[4]);
    expect(rightSplitted, isNotNull);
    expect(rightSplitted!.length, equals(2));
    // was splitted from the offset passed
    expect(line.nsText, equals('use '));
    // and here is where end the part of the line splitted
    expect(rightSplitted.first.text, equals("it "));
    expect(context.executed, isTrue);
    expect(context.changeSize, equals(108));
    expect(context.node, equals(block));
    expect(block.length, equals(2));
    expect(location.node, isNotNull);
    expect(location.found, isTrue);
    expect(location.fragmentIndex, equals(0));
    expect(
      location.node!.value.castToFragments()[location.fragmentIndex].data,
      equals(obj),
    );
    expect(line.parent, block);
    expect(endLineSibling.parent, isNot(equals(block)));
    expect(endLineSibling.parent, equals(rightSplitted));
  });

  test('insert text at start of a node', () {
    expect(root, isNotNull);
    final FragmentChangeContext context = root!.insert(
      122,
      '|',
    );

    expect(context.executed, isTrue);
    expect(context.changeSize, equals(1));
    expect(context.paths, equals(<int>[0]));
    expect(context.node!.deepPath, equals(<int>[5, 0]));
    expect(context.node!.toPlainText(), equals('|So, since we are just '));
  });

  test('insert text at the end of a node', () {
    expect(root, isNotNull);
    final FragmentChangeContext context = root!.insert(
      203,
      '|',
    );

    expect(context.executed, isTrue);
    expect(context.changeSize, equals(1));
    expect(context.paths, equals(<int>[0]));
    expect(context.node!.deepPath, equals(<int>[5, 2]));
    expect(context.node!.toPlainText(),
        equals('to take as an example how work this visualizer (2). |'));
  });

  test('insert text in middle of document', () {
    expect(root, isNotNull);
    final Node? block = root!.queryPath(<int>[6]);
    expect(block, isNotNull);
    expect(block!.children, isNotEmpty);
    final FragmentChangeContext context = block.insert(
      6,
      'Test ',
    );

    expect(context.executed, isTrue);
    expect(context.changeSize, equals(5));
    expect(context.paths, equals(<int>[0]));
    expect(context.node!.deepPath, equals(<int>[6, 0]));
    expect(context.node!.toPlainText(), equals('First Test example:'));
  });

  test('insert text backward an embed', () {
    expect(root, isNotNull);
    final Node? embedBlock = root!.queryPath(<int>[1]);
    expect(embedBlock, isNotNull);
    expect(embedBlock!.children, isNotEmpty);
    expect(embedBlock.text, equals(Node.kObjectReplacementCharacter));
    final FragmentChangeContext context = root!.insert(
      1,
      'Test ',
    );

    expect(context.executed, isTrue);
    expect(context.changeSize, equals(5));
    expect(context.paths, equals(<int>[0]));
    final Node? newBlock = root!.queryPath(<int>[1]);
    expect(newBlock, isNotNull);
    expect(context.node!.jumpToParentExceptRoot(), equals(newBlock));
    expect(embedBlock.deepPath, equals(<int>[2]));
    expect(context.node!.deepPath, equals(<int>[1, 0]));
    expect(context.node!.toPlainText(), equals('Test '));
  });

  test('insert text at end of document', () {
    expect(root, isNotNull);
    final FragmentChangeContext context = root!.insert(
      318,
      'Test ',
    );

    expect(context.executed, isTrue);
    expect(context.changeSize, equals(5));
    expect(context.paths, equals(<int>[0]));
    expect(context.node!.deepPath, equals(<int>[9, 0]));
    expect(context.node!.text, equals('Test '));
  });
}
