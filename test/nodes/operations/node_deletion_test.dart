import 'package:easy_rich_editor/easy_rich_editor.dart';
import 'package:easy_rich_editor/src/core/extensions/object_ext.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../resources/doc_rs.dart';

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

  test('Delete a character in middle of text', () {
    final FragmentChangeContext context = root.delete(
      100,
      112,
    );

    expect(context.executed, isTrue);
    expect(context.changeSize, equals(12));
    expect(context.paths, equals(<int>[0]));
    expect(context.node!.deepPath, equals(<int>[2, 2]));
    expect(
      context.node!.toPlainText(),
      equals('to take as an example how work this visu'),
    );
  });
  test('Delete two nodes that are being selected', () {
    // deletes almost the text into the block matched
    final FragmentChangeContext context = root.delete(
      4,
      100,
    );

    expect(context.executed, isTrue);
    expect(context, isA<MultipleFragmentChangeContext>());
    expect(context.changeSize, equals(96));
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
      context.node!.toPlainText(),
      equals('alizer (1). '),
    );
  });
  test('Delete embed', () {});
  test('Delete entire document content', () {});
}
