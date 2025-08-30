import 'dart:collection';

import 'package:easy_rich_editor/easy_rich_editor.dart';
import 'package:easy_rich_editor/src/core/extensions/object_ext.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../resources/doc_rs.dart';

void main() {
  Node? root;

  setUp(() {
    root = DocumentToNodesParser.documentParse(commonDoc);
  });

  test('Delete all the text of a node', () {
    expect(root, isNotNull);
    final FragmentChangeContext context = root!.delete(
      0,
      1,
    );
    expect(context.executed, isTrue);
    expect(context.changeSize, equals(1));
    expect(() => context.node!.deepPath, throwsA(isA<Exception>()));
    expect(context.node!.jumpToParent().isRootOwner, isFalse);
    expect(root!.contains(context.node!.id), isFalse);
  });

  test('Delete one character in middle of text', () {
    expect(root, isNotNull);
    final FragmentChangeContext context = root!.delete(
      62,
      1,
    );

    expect(context.executed, isTrue);
    expect(context.changeSize, equals(1));
    expect(context.node!.deepPath, equals(<int>[2, 2]));
    expect(
      context.node!.toPlainText(),
      equals('to ake as an example how work this visualizer (1). '),
    );
  });

  test('Delete two nodes that are being selected', () {
    // deletes almost the text into the block matched
    expect(root, isNotNull);
    final FragmentChangeContext context = root!.delete(
      3,
      89,
    );

    expect(context.executed, isTrue);
    expect(context, isA<MultipleFragmentChangeContext>());
    expect(context.changeSize, equals(89));
    expect(context.node!.deepPath, equals(<int>[2]));
    expect(
        context
            .cast<MultipleFragmentChangeContext>()
            .changes
            .first
            .node!
            .deepPath,
        equals(<int>[2, 0]));
    expect(
      context.node!.text,
      equals('alizer (1). '),
    );
  });

  test('Delete embed when required', () {
    // deletes almost the text into the block matched
    expect(root, isNotNull);
    final Node? embed = root!.queryPath(<int>[1]);
    expect(embed, isNotNull);
    expect(embed!.type, equals(EmbedKeys.key));
    expect(embed.isNotEmpty, isTrue);
    expect(embed.parent, isNotNull);
    expect(embed.parent, equals(root));
    final FragmentChangeContext context = root!.delete(
      1,
      1,
    );

    expect(root!.contains(embed.id), isFalse);
    expect(embed.parent, isNull);
    expect(context.executed, isTrue);
    expect(context.changeSize, equals(1));
  });

  test('Should delete node when is empty', () {
    // deletes almost the text into the block matched
    expect(root, isNotNull);
    final Node? newLineBlock = root!.queryPath(<int>[3]);
    expect(newLineBlock, isNotNull);
    expect(newLineBlock!.type, equals(ParagraphKeys.key));
    expect(newLineBlock.isNotEmpty, isTrue);
    expect(newLineBlock.parent, isNotNull);
    expect(newLineBlock.parent, equals(root));
    final FragmentChangeContext context = root!.delete(
      112,
      1,
    );

    expect(root!.contains(newLineBlock.id), isFalse);
    expect(newLineBlock.parent, isNull);
    expect(context.executed, isTrue);
    expect(context.changeSize, equals(1));
  });

  test('Should delete first empty node', () {
    // deletes almost the text into the block matched
    expect(root, isNotNull);
    final Node? firstNewLineBlock = root!.queryPath(<int>[0]);
    expect(firstNewLineBlock, isNotNull);
    expect(firstNewLineBlock!.type, equals(ParagraphKeys.key));
    expect(firstNewLineBlock.isNotEmpty, isTrue);
    expect(firstNewLineBlock.parent, isNotNull);
    expect(firstNewLineBlock.parent, equals(root));

    final Node? lastLineBlock = root!.queryPath(<int>[9]);
    expect(lastLineBlock, isNotNull);
    expect(lastLineBlock!.type, equals(ParagraphKeys.key));
    expect(lastLineBlock.isNotEmpty, isTrue);
    expect(lastLineBlock.parent, isNotNull);
    expect(lastLineBlock.parent, equals(root));
    // deletes the first block in the document
    final FragmentChangeContext context = root!.delete(
      0,
      1,
    );

    // deletes the last block in the document
    final FragmentChangeContext context2 = root!.delete(
      317,
      1,
    );

    expect(context.executed, isTrue);
    expect(context2.executed, isTrue);
    expect(context.changeSize, equals(1));
    expect(context2.changeSize, equals(1));
    expect(root!.contains(firstNewLineBlock.id), isFalse);
    expect(root!.contains(lastLineBlock.id), isFalse);
    expect(firstNewLineBlock.parent, isNull);
    expect(lastLineBlock.parent, isNull);
    expect(lastLineBlock.parent, isNot(equals(root)));
    expect(
      root!.changes!,
      equals(
        HashMap<String, int>.from(
          <String, int>{
            lastLineBlock.id: 0,
            firstNewLineBlock.id: 0,
          },
        ),
      ),
    );
  });

  test('Should ignores deletion if there\'s no element to remove', () {
    expect(root, isNotNull);
    final Node lastEmptyNode = root!.last;
    expect(root!.contains(lastEmptyNode.id), isTrue);
    // tries to delete one character forward
    // but is ignored
    final FragmentChangeContext context = root!.delete(
      318,
      1,
      forward: true,
    );

    expect(root!.contains(lastEmptyNode.id), isTrue);
    expect(context.executed, isFalse);
    expect(context.changeSize, equals(-1));
    expect(context.reason, equals(NoExecutionReason.invalidEnd));

    final FragmentChangeContext contextExecuted = root!.delete(
      318,
      1,
    );

    expect(root!.contains(lastEmptyNode.id), isFalse);
    expect(contextExecuted.executed, isTrue);
    expect(contextExecuted.changeSize, equals(1));
    expect(contextExecuted.reason, isNull);
  });
}
