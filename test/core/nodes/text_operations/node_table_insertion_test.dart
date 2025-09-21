// ignore_for_file: unused_local_variable

import 'package:easy_rich_editor/easy_rich_editor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Node? root;

  setUp(() {
    root = ObjectToNodesParser.json(Node.root(
      children: <Node>[
        Node.block(data: 'this is my simple text at the start of the document'),
        Node.embedBlock(data: <String, String>{'image': 'image.png'}),
        Node.block(data: 'this is my simple text after an embed'),
        Node.block(data: 'this is my \nsimple text before a table'),
        Node.table(
          // just pass the num of rows
          // when you know that you are
          // passing to [rows] the exact
          // list length
          rows: <Node>[
            Node.tableRow(columnNum: 2, children: <Node>[
              Node.block(data: 'This is my text \ninto the first column'),
            ]),
            Node.tableRow(columnNum: 2, children: <Node>[
              Node.block(data: 'This is my text into the middle column'),
            ]),
            Node.tableRow(columnNum: 2, children: <Node>[
              Node.block(data: 'This is my text into the end column'),
            ]),
          ],
        ),
        Node.block(data: 'this is\nmy simple text 2'),
        Node.block(data: 'this is my simple\ntext 3'),
        Node.block(data: 'this is my simple text 4'),
      ],
    ).toJson());
  });

  group('insert', () {
    test('should insert a single char in the end column', () {});
    test('should insert a text using paths', () {});
    test('should insert a text using document offsets', () {});
    test('should insert a embed correctly', () {});
    test('should insert a text correctly', () {});
  });
  group('delete', () {
    test('should insert a single char in the end column', () {});
    test('should insert a text using paths', () {});
    test('should insert a text using document offsets', () {});
    test('should insert a embed correctly', () {});
    test('should insert a text correctly', () {});
  });
}
