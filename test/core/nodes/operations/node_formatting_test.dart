import 'package:easy_rich_editor/attributes.dart';
import 'package:easy_rich_editor/easy_rich_editor.dart';
import 'package:easy_rich_editor/src/core/api/attributes/builtin/block/header_attr.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../resources/doc_rs.dart';

void main() {
  Node? root;

  setUp(() {
    root = DocumentToNodesParser.documentParse(commonDoc);
  });

  test('should format a single char', () {
    final FragmentChangeContext context = root!.format(
      0,
      1,
      formatBlock: true,
      modifier: NodeModifier.defaultModifier,
      attributes: <Attribute<dynamic>>[
        BoldAttribute(value: true),
        HeaderAttribute(value: 1),
      ],
    );
  });
  test('should format entire block children', () {});
  test('should format single block attributes', () {});
  test('should format more than one block with block level attributes', () {});
  test('should format more than one line with inline attributes', () {});
  test('should unformat when toggle attributes in specified offset', () {});
  test('should unformat when toggle block attributes in specified offset',
      () {});
}
