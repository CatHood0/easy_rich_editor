import 'package:easy_rich_editor/attributes.dart';
import 'package:easy_rich_editor/easy_rich_editor.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../resources/doc_rs.dart';

void main() {
  Node? root;

  setUp(() {
    root = DocumentToNodesParser.documentParse(commonDoc);
  });

  test('should format a single char', () {
    expect(root, isNotNull);
    final Node? line = root!.queryPath(<int>[2, 0]);
    expect(line, isNotNull);
    final FragmentChangeContext context = line!.format(
      2,
      1,
      formatBlock: false,
      modifier: NodeModifier.defaultModifier,
      attributes: <EasyAttribute<dynamic>>[
        BoldAttribute(value: true),
      ],
    );
    line.format(
      14,
      2,
      formatBlock: false,
      modifier: NodeModifier.defaultModifier,
      attributes: <EasyAttribute<dynamic>>[
        ItalicAttribute(value: true),
      ],
    );
    print(line.dumpTreeStr());
  });
  test('should format entire block children', () {});
  test('should format single block attributes', () {});
  test('should format more than one block with block level attributes', () {});
  test('should format more than one line with inline attributes', () {});
  test('should unformat when toggle attributes in specified offset', () {});
  test('should unformat when toggle block attributes in specified offset',
      () {});
}
