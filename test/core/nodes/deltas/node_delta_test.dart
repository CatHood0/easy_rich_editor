import 'package:easy_attribution_text/easy_text.dart';
import 'package:easy_rich_editor/easy_rich_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final EasyDocument document = EasyDocument(
    Node.root(
      children: <Node>[
        Node.block(
          children: <Node>[
            Node.lineBlock(
              data: EasyTextList.from(<EasyText>[
                EasyText.fromStr(text: 'This is a single text line'),
              ]),
            ),
            Node.lineBlock(
              data: EasyTextList.from(<EasyText>[
                EasyText.fromStr(text: 'Where we expose how works '),
                EasyText.fromStr(
                    text: 'DeltaNode',
                    styles: EasyAttributeStyles.fromIterable(
                      <EasyAttribute<Object?>>[
                        BoldAttribute(),
                        InlineCodeAttribute(),
                      ],
                    )),
                EasyText.fromStr(text: ' in easy_rich_editor package'),
              ]),
            ),
          ],
        ),
        Node.block(
          children: <Node>[
            Node.lineBlock(
              data: EasyTextList.from(<EasyText>[
                EasyText.fromStr(
                    text: 'This is a newly added paragraph with text content'),
              ]),
            ),
          ],
        ),
        Node.embedBlock(data: {'image': 'path.jpg'}),
        Node.block(
          children: <Node>[
            Node.lineBlock(
              data: EasyTextList.from(<EasyText>[
                EasyText.fromStr(
                    text: 'Final paragraph demonstrating the structure'),
                EasyText.fromStr(
                  text: ' with formatted text',
                  styles: EasyAttributeStyles.fromIterable(
                    <EasyAttribute<Object?>>[
                      ItalicAttribute(),
                      UnderlineAttribute(),
                    ],
                  ),
                ),
              ]),
            ),
          ],
        ),
      ],
    ),
    maxRecordLimit: 300,
  );

  setUp(() {
    expect(document.length, equals(4),
        reason: 'Expected 5 children, '
            'but found ${document.length} '
            '=> ${document.root.dumpTreeStr()}');
  });

  test('should add and remove text easily', () {
    final Node clone = document.first!.deepCopy();
    const String text = '-aaaaaa- ';
    document.applyDelta(
      DeltaNode.insert(
        insert: text,
        start: 4,
        styles: EasyAttributeStyles.empty(),
      ),
    );
    final List<NodeValueLocation> values = document.queryValue(text);
    expect(values.length, equals(1));
    expect(values.single.ranges.length, equals(1));
    expect(
      values.single.ranges.single,
      equals(
        TextRange(start: 4, end: 13),
      ),
    );
    expect(
      values.single.location,
      equals(NodeLocation(
        path: document.first!.first.deepPath,
        node: document.first!.first,
      )),
    );
    document.applyDelta(
      DeltaNode.delete(
        start: 4,
        len: text.length,
      ),
    );

    final List<NodeValueLocation> values2 = document.queryValue(text);
    expect(values2.length, equals(0));
    expect(document.first!.equals(clone), isFalse);
  });

  test('should add and remove text easily between multiple nodes', () {

  });
  test('should use multiple operations to apply deltas', () {});
}
