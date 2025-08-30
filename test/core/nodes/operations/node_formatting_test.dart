import 'package:easy_attribution_text/easy_text.dart';
import 'package:easy_rich_editor/easy_rich_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../resources/doc_rs.dart';

void main() {
  Node? root;

  setUp(() {
    root = DocumentToNodesParser.documentParse(commonDoc);
  });

  test('should format a single char', () {
    expect(root, isNotNull);
    final Node line = root!.queryPath(<int>[2, 0])!;
    expect(line.texts.length, equals(1));
    expect(
      line.texts.first.text,
      'This is just a simple document where we can just '.characters,
    );
    line.format(
      2,
      1,
      formatBlock: false,
      attributes: EasyAttributeStyles.fromAttribute(BoldAttribute()),
    );

    expect(line.texts.length, equals(3));
    expect(line.texts.first.text, 'Th'.characters);
    expect(
      line.texts.first.styles,
      equals(EasyAttributeStyles.empty()),
    );
    EasyText? next = line.texts.first.next;
    expect(next, isNotNull);
    expect(next!.text, 'i'.characters);
    expect(
      next.styles,
      equals(EasyAttributeStyles.fromAttribute(BoldAttribute())),
    );
    expect(next.next, equals(line.texts.last));
  });

  test('should format two times selections in the same block line', () {
    expect(root, isNotNull);

    final Node line = root!.queryPath(<int>[2, 0])!;
    expect(line.texts.length, equals(1));
    expect(
      line.texts.first.text,
      'This is just a simple document where we can just '.characters,
    );
    line.format(
      2,
      1,
      formatBlock: false,
      attributes: EasyAttributeStyles.fromAttribute(BoldAttribute()),
    );

    expect(line.texts.length, equals(3));
    expect(line.texts.first.text, 'Th'.characters);
    expect(
      line.texts.first.styles,
      equals(EasyAttributeStyles.empty()),
    );
    EasyText? next = line.texts.first.next;
    expect(next, isNotNull);
    expect(next!.text, 'i'.characters);
    expect(
      next.styles,
      equals(EasyAttributeStyles.fromAttribute(BoldAttribute())),
    );
    line.format(
      14,
      4,
      formatBlock: false,
      attributes: EasyAttributeStyles.fromAttribute(ItalicAttribute()),
    );
    expect(line.texts.length, equals(5));
    expect(next.next, isNotNull);
    next = next.next;
    expect(next, isNotNull);
    expect(next!.text, equals('s is just a si'.characters));
    expect(next.styles, equals(EasyAttributeStyles.empty()));
    next = next.next;
    expect(next, isNotNull);
    // moves to the node where were applied the italic attribution
    expect(next!.text, 'mple'.characters);
    expect(
      next.styles,
      equals(EasyAttributeStyles.fromAttribute(ItalicAttribute())),
    );
    expect(next.next, equals(line.texts.last));
  });
  test('should format entire block children', () {});
  test('should format single block attributes', () {});
  test('should format more than one block with block level attributes', () {});
  test('should format more than one line with inline attributes', () {});
  test('should unformat when toggle attributes in specified offset', () {});
  test(
    'should unformat when toggle block attributes in specified offset',
    () {},
  );
}
