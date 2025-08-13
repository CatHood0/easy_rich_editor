import 'package:easy_rich_editor/easy_rich_editor.dart';
import 'package:easy_rich_editor/src/core/api/document/path/path.dart';
import 'package:flutter_quill_delta_easy_parser/flutter_quill_delta_easy_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Node Basic Functionality', () {
    test('Root node initialization', () {
      final Node root = Node.root();
      expect(root.type, equals(Node.rootId));
      expect(root.isRootOwner, isTrue);
      expect(root.parent, isNull);
      expect(root.children, isEmpty);
    });

    test('Child node initialization', () {
      final Node root = Node.root();
      final Node child = Node(
        type: ParagraphKeys.key,
        value: null,
      );

      root.adoptChild(child);

      expect(child.parent, equals(root));
      expect(root.children, contains(child));
    });
  });

  group('Offset Calculations', () {
    late Node root;
    late Node paragraph1;
    late Node paragraph2;
    late Node line1;
    late Node line2;

    setUp(() {
      paragraph1 = Node(type: ParagraphKeys.key, value: null);
      paragraph2 = Node(type: ParagraphKeys.key, value: null);
      root = Node.root(children: <Node>[paragraph1, paragraph2]);
      line1 = Node(
        type: ParagraphKeys.lineKey,
        value: <TextFragment>[TextFragment(data: 'Hello')],
        canModifyChildrenLength: false,
      );

      line2 = Node(
        type: ParagraphKeys.lineKey,
        value: <TextFragment>[TextFragment(data: 'World')],
        canModifyChildrenLength: false,
      );
      paragraph1.adoptChild(line1, paragraph1.length.prev.nonNegative);
      paragraph2.adoptChild(line2, paragraph2.length.prev.nonNegative);
    });

    test('Global offsets for simple structure', () {
      expect(root.globalOffset, equals(0));
      expect(paragraph1.globalOffset, equals(0));
      expect(line1.globalOffset, equals(0));
      expect(paragraph2.globalOffset, equals(5)); // 'Hello' = 5 chars
      expect(line2.globalOffset, equals(5));
    });

    test('End offsets calculation', () {
      expect(line1.globalEnd, equals(5));
      expect(paragraph1.globalEnd, equals(5));
      expect(line2.globalEnd, equals(10)); // 'HelloWorld' = 10 chars
      expect(paragraph2.globalEnd, equals(10));
    });

    test('Offset invalidation', () {
      final int initialOffset = line2.globalOffset;
      line1.value = <TextFragment>[
        TextFragment(data: 'Hi')
      ]; // Change from 'Hello' to 'Hi'

      expect(line2.globalOffset, isNot(equals(initialOffset)));
      expect(line2.globalOffset, equals(2)); // 'Hi' = 2 chars
    });
  });

  group('Tree Navigation', () {
    late Node root;
    late Node paragraph1, paragraph2;
    late Node line1, line2;

    setUp(() {
      root = Node.root();
      paragraph1 = Node(type: ParagraphKeys.key, value: null, parent: root);
      line1 = Node(
        type: ParagraphKeys.lineKey,
        value: <TextFragment>[TextFragment(data: 'First')],
        canModifyChildrenLength: false,
      );
      paragraph2 = Node(type: ParagraphKeys.key, value: null, parent: root);
      line2 = Node(
        type: ParagraphKeys.lineKey,
        value: <TextFragment>[TextFragment(data: 'Second')],
        canModifyChildrenLength: false,
      );
      root.adoptChildren(<Node>[paragraph1, paragraph2]);
      paragraph1.adoptChild(line1, paragraph1.length.prev.nonNegative);
      paragraph2.adoptChild(line2, paragraph2.length.prev.nonNegative);
    });

    test('Next and previous nodes', () {
      expect(line1.next, isNull); // No next at same level
      expect(paragraph1.next, equals(paragraph2));
      expect(paragraph2.previous, equals(paragraph1));
    });

    test('First and last child', () {
      expect(root.firstChild, equals(paragraph1));
      expect(root.lastChild, equals(paragraph2));
      expect(paragraph1.firstChild, equals(line1));
    });
  });

  group('Path Calculations', () {
    late Node root;
    late Node paragraph1, paragraph2, paragraph3;

    setUp(() {
      root = Node.root();
      paragraph1 = Node(type: ParagraphKeys.key, value: null, parent: root);
      paragraph2 = Node(type: ParagraphKeys.key, value: null, parent: root);
      paragraph3 = Node(type: ParagraphKeys.key, value: null, parent: root);
      root.adoptChildren(<Node>[paragraph1, paragraph2, paragraph3]);
    });

    test('Path computation', () {
      expect(paragraph1.path, equals(0));
      expect(paragraph2.path, equals(1));
      expect(paragraph3.path, equals(2));
    });

    test('Deep path computation', () {
      final Node line = Node(
        type: ParagraphKeys.lineKey,
        value: <TextFragment>[TextFragment(data: 'Test')],
        parent: paragraph2,
        canModifyChildrenLength: false,
      );
      paragraph2.adoptChildren(<Node>[line]);

      expect(
          line.deepPath, equals(<int>[1, 0])); // [paragraph2 index, line index]
    });

    test('Path invalidation on insertion', () async {
      final Node newParagraph = Node(type: ParagraphKeys.key, value: null);
      paragraph2.insertBefore(newParagraph);
      expect(newParagraph.path, equals(1));
      expect(paragraph2.path, equals(2));
      expect(paragraph3.path, equals(3));
    });
  });

  group('Edge Cases', () {
    test('Empty nodes handling', () {
      final Node root = Node.root();
      final Node emptyParagraph = Node(
        type: ParagraphKeys.key,
        value: null,
        parent: root,
      );
      final Node emptyLine = Node(
        type: ParagraphKeys.lineKey,
        value: <TextFragment>[],
        parent: emptyParagraph,
        canModifyChildrenLength: false,
      );
      emptyParagraph.adoptChild(
        emptyLine,
        emptyParagraph.length.prev.nonNegative,
      );
      root.adoptChildren(<Node>[emptyParagraph]);

      expect(emptyLine.globalOffset, equals(0));
      expect(emptyLine.globalEnd, equals(0));
    });

    test('Nodes with special characters', () {
      final Node root = Node.root();
      final Node paragraph =
          Node(type: ParagraphKeys.key, value: null, parent: root);
      final Node line = Node(
        type: ParagraphKeys.lineKey,
        value: <TextFragment>[
          TextFragment(data: 'Hello'),
          TextFragment(data: Node.kObjectReplacementCharacter),
          TextFragment(data: 'World'),
        ],
        parent: paragraph,
        canModifyChildrenLength: false,
      );
      paragraph.adoptChild(
        line,
        paragraph.length.prev.nonNegative,
      );
      root.adoptChildren(<Node>[paragraph]);

      expect(line.dataLength, equals(11)); // 'Hello' + object char + 'World'
    });

    test('Large tree performance', () {
      final Node root = Node.root();
      Node currentParent = root.deepCopy();

      // Create a deep tree
      for (int i = 0; i < 100; i++) {
        final Node newNode = Node(
          type: 'level$i',
          value: null,
          parent: currentParent,
        );
        currentParent.adoptChild(newNode);
        currentParent = newNode;
      }

      // Verify deep path calculation doesn't stack overflow
      expect(currentParent.deepPath, hasLength(100));
    });
  });

  group('Modification Operations', () {
    late Node root;
    late Node paragraph;

    setUp(() {
      root = Node.root();
      paragraph = Node(type: ParagraphKeys.key, value: null, parent: root);
      root.adoptChildren(<Node>[paragraph]);
      final Node line = Node(
        type: ParagraphKeys.lineKey,
        value: <TextFragment>[TextFragment(data: 'First line')],
        canModifyChildrenLength: false,
      );
      paragraph.adoptChild(line);
    });

    test('Insert before', () {
      final Node newLine = Node(
        type: ParagraphKeys.lineKey,
        value: <TextFragment>[TextFragment(data: 'New line')],
        canModifyChildrenLength: false,
      );
      paragraph.firstChild!.insertBefore(newLine);

      expect(paragraph.children.length, equals(2));
      expect(paragraph.firstChild, equals(newLine));
      expect(newLine.globalOffset, equals(0));
    });

    test('Insert after', () {
      final Node newLine = Node(
        type: ParagraphKeys.lineKey,
        value: <TextFragment>[TextFragment(data: 'New line')],
        canModifyChildrenLength: false,
      );
      paragraph.firstChild!.insertAfter(newLine);

      expect(paragraph.children.length, equals(2));
      expect(paragraph.lastChild, equals(newLine));
      expect(newLine.globalOffset, equals(10)); // After 'First line'
    });

    test('Unlink node', () {
      final Node line = paragraph.firstChild!..unlink();

      expect(paragraph.children, isEmpty);
      expect(line.parent, isNull);
    });
  });

  group('Text Fragments Handling', () {
    test('Multiple fragments length calculation', () {
      final Node node = Node(
        type: ParagraphKeys.lineKey,
        value: <TextFragment>[
          TextFragment(data: 'Hello'),
          TextFragment(data: ' '),
          TextFragment(data: 'World'),
        ],
        canModifyChildrenLength: false,
      );

      expect(node.dataLength, equals(11));
    });

    test('Plain text conversion', () {
      final Node node = Node(
        type: ParagraphKeys.lineKey,
        value: <TextFragment>[
          TextFragment(
              data: 'Hello', attributes: <String, dynamic>{'bold': true}),
          TextFragment(data: ' '),
          TextFragment(data: 'World'),
        ],
        canModifyChildrenLength: false,
      );

      expect(node.toPlainText(), equals('Hello World'));
    });
  });
}
