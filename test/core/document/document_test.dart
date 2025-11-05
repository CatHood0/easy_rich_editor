import 'package:easy_attribution_text/easy_text.dart';
import 'package:easy_rich_editor/easy_rich_editor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final Node root = Node.root(
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
              EasyText.fromStr(text: 'This is the middle text line'),
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
                  text: 'This is a single text line in the end block'),
            ]),
          ),
          Node.lineBlock(
            data: EasyTextList.from(<EasyText>[
              EasyText.fromStr(text: 'end line'),
            ]),
          ),
        ],
      ),
    ],
  );
  final EasyDocument document = EasyDocument(
    root,
    maxRecordLimit: 300,
  );

  group('crud operations', () {});
  group('applying EasyOperations instances', () {});
  group('undo and redo', () {});
  group('selection', () {
    test('should return the multi nodes selection', () {
      final List<Node> selection = document.getSelectedNodes(
        NodeSelection(
          start: NodePosition(
            path: <int>[0, 0],
            posOffset: 1,
            id: document.queryPath(<int>[0, 0])!.id,
          ),
          end: NodePosition(
            path: <int>[0, 1],
            posOffset: 6,
            id: document.queryPath(<int>[0, 1])!.id,
          ),
        ),
      );
      expect(
        selection,
        equals(
          <Node>[
            document.first!.first,
            document.first!.elementAt(1),
          ],
        ),
      );
    });
  });
  group('queries', () {});
}
