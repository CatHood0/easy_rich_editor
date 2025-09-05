import 'package:easy_attribution_text/easy_text.dart';
import 'package:easy_rich_editor/easy_rich_editor.dart';
import 'package:easy_rich_editor/src/core/extensions/fragments/fragments_ext.dart';
import 'package:easy_rich_editor/src/core/extensions/object_ext.dart';
import 'package:flutter_quill_delta_easy_parser/flutter_quill_delta_easy_parser.dart'
    as pr;
import 'package:flutter_quill_delta_easy_parser/flutter_quill_delta_easy_parser.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../resources/doc_rs.dart';

void main() {
  test('should return exact node from json', () {
    final Node root = ObjectToNodesParser.json(<String, dynamic>{
      'id': Node.rootId,
      'type': Node.rootId,
      'metadata': <dynamic, dynamic>{
        'root': true,
        'block': false,
      },
      'value': null,
      // blocks
      'children': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'pr-1',
          'type': ParagraphKeys.key,
          'metadata': <dynamic, dynamic>{
            'block': true,
            'pr_attributes': null,
          },
          // lines
          'children': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'line-1',
              'type': ParagraphKeys.lineKey,
              'metadata': <dynamic, dynamic>{'block': false},
              'value': <Map<String, dynamic>>[
                <String, dynamic>{
                  'id': 'text-1',
                  'text': 'sample text in a json',
                  'styles': <String, dynamic>{},
                },
              ],
            },
          ],
        },
        <String, dynamic>{
          'id': 'embed-2',
          'type': EmbedKeys.key,
          'metadata': <dynamic, dynamic>{
            'block': true,
            'pr_attributes': null,
          },
          // lines
          'children': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'embed-line-2',
              'type': EmbedKeys.childrenKey,
              'value': TextFragment(
                data: <String, dynamic>{'image': 'path'},
              ).toJson(),
              'children': <dynamic>[],
            },
          ],
        },
        <String, dynamic>{
          'id': 'pr-3',
          'type': ParagraphKeys.key,
          'metadata': <dynamic, dynamic>{
            'block': true,
            'pr_attributes': null,
          },
          // lines
          'children': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'line-3',
              'type': ParagraphKeys.lineKey,
              'metadata': <dynamic, dynamic>{'block': false},
              'value': <Map<String, dynamic>>[
                <String, dynamic>{
                  'id': 'text-3',
                  'text': 'sample text in a json in the last line',
                  'styles': <String, dynamic>{},
                },
              ],
            },
          ],
        },
      ],
    });

    expect(root.id, equals(Node.rootId));
    expect(root.children.length, equals(3));
    // now expecting blocks
    final Node pr1 = root.first;
    final Node embed2 = pr1.next!;
    final Node pr3 = root.last;
    expect(pr1.id, equals('pr-1'));
    expect(pr1.type, equals(ParagraphKeys.key));
    expect(embed2.id, equals('embed-2'));
    expect(embed2.type, equals(EmbedKeys.key));
    expect(pr3.id, equals('pr-3'));
    expect(pr3.type, equals(ParagraphKeys.key));
    // now expecting children lines
    expect(pr1.first.id, equals('line-1'));
    expect(pr1.first.type, equals(ParagraphKeys.lineKey));
    expect(embed2.first.id, equals('embed-line-2'));
    expect(embed2.first.type, equals(EmbedKeys.childrenKey));
    expect(pr3.first.id, equals('line-3'));
    expect(pr3.first.type, equals(ParagraphKeys.lineKey));
    // now expecting values
    expect(pr1.first.value, isA<EasyTextList>());
    expect(pr1.first.value.castToEasyText().length, equals(1));
    expect(pr1.first.value.castToEasyText().toPlainText(), equals('sample text in a json'));
    expect(embed2.first.value, isA<TextFragment>());
    expect(embed2.first.value.castToFragment().data,
        equals(<String, dynamic>{'image': 'path'}));
    expect(pr3.first.value, isA<EasyTextList>());
    expect(pr3.first.value.castToEasyText().length, equals(1));
    expect(pr3.first.value.castToEasyText().toPlainText(), equals('sample text in a json in the last line'));
  });

  test('jump to parent effectively', () {
    final pr.Document doc = commonDoc;
    final Node root = ObjectToNodesParser.documentParse(doc);
    final Node paragraph = root.queryPath(<int>[3])!;
    final Node node = Node(
      type: ParagraphKeys.lineKey,
      value: <pr.TextFragment>[
        pr.TextFragment(data: "This is my example text "),
        pr.TextFragment(data: "So, i want to know "),
        pr.TextFragment(
            data: "if is this good?",
            attributes: <String, dynamic>{'bold': true}),
      ].toEasyList(),
      id: 'Test id',
      canModifyChildrenLength: false,
    );

    paragraph.insertNode(node, path: 0, after: true);
    final Node rootNode = node.jumpToParentExceptRoot()!;

    expect(rootNode.id, paragraph.id);
    expect(rootNode, paragraph);
  });

  test('just a simple text to know if the tree works as expected', () {
    final pr.Document doc = commonDoc;
    final Node root = ObjectToNodesParser.documentParse(doc);
    final Node paragraph = root.queryPath(<int>[3])!;
    final Node node = Node(
      type: ParagraphKeys.lineKey,
      value: <pr.TextFragment>[
        pr.TextFragment(data: "This is my example text "),
        pr.TextFragment(data: "So, i want to know "),
        pr.TextFragment(
            data: "if is this good?",
            attributes: <String, dynamic>{'bold': true}),
      ].toEasyList(),
      id: 'Test id',
      canModifyChildrenLength: false,
    );

    paragraph.insertNode(node, path: 0, after: false);
    expect(node.parent, isNotNull);
    expect(node.parent, paragraph);
    expect(paragraph.contains(node.id), isTrue);
  });
}
