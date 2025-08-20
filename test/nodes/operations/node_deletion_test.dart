import 'package:easy_rich_editor/easy_rich_editor.dart';
import 'package:easy_rich_editor/src/core/extensions/object_ext.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../resources/doc_rs.dart';

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
    expect(context.paths, equals(<int>[0]));
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
    expect(context.paths, equals(<int>[0]));
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
      2,
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
      111,
      1,
      forward: true,
    );
    print(root!.dumpTreeStr(currentPath: <int>[3, 0]));

    expect(root!.contains(newLineBlock.id), isFalse);
    expect(newLineBlock.parent, isNull);
    expect(context.executed, isTrue);
    expect(context.changeSize, equals(1));
  });
  test('Delete entire document content', () {});
}
