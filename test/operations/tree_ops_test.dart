import 'package:easy_rich_editor/internal.dart';
import 'package:easy_rich_editor/easy_rich_editor.dart';
import 'package:flutter_quill_delta_easy_parser/blocks/text_fragment.dart';
import 'package:flutter_test/flutter_test.dart';
import '../resources/doc_rs.dart';

void main() {
  final Node root = DocumentToNodesParser.documentParse(commonDoc);
  final Tree tree = Tree(root);

  group('Queries', () {
    test('Just print', () {
      final Node paragraph = tree.queryPath([3])!;
      final Node node = Node(
        type: ParagraphKeys.lineKey,
        value: [
          TextFragment(data: "This is my example text bitch. "),
          TextFragment(data: "So, i want to know "),
          TextFragment(data: "why (2)", attributes: {'bold': true}),
        ],
        id: 'Test id 2',
        canModifyChildrenLength: false,
      );

      paragraph.insertNode(node, path: 0, after: false);
      print(tree.printLines());
      paragraph.parent?.removeNode(paragraph);
      print(tree.printLines());
    });
    test('Query Node by id', () {
      final Node? node = tree.query("normal pr 2");
      expect(node, isNotNull);
    });
    test('Query Node by full path', () {
      final Node? node = tree.queryPath([3, 0, 0]);
      expect(node, isNotNull);
    });
    test('Query List of locations by the given text', () {
      final List<NodeValueLocation> locations =
          tree.queryValue("take", caseSensitive: false);
      expect(locations, isNotNull);
      expect(locations, isNotEmpty);
      expect(
        locations.first.location.path,
        <int>[2, 2, 0],
      );
      expect(
        locations.last.location.path,
        <int>[5, 2, 0],
      );
    });
  });

  group('Add nodes', () {
    test('insert node at start', () {
      final node = randomNode;
      tree.addNode(node, after: false, paths: [0]);

      expect(node.parent, isNotNull);
      expect(node.parent, tree.root);
      expect(
        tree.queryPath([0]),
        node,
      );
    });
    test('insert node at end', () {});
    test('insert node at path', () {});
  });

  group('Insert', () {
    test('insert text', () {});
    test('insert text at path', () {});
    test('insert text at node', () {});
    test('insert Node', () {});
    test('Ensure that needs path computing after insertion', () {});
    test('insert List of Nodes', () {});
  });

  group('Update', () {
    test('Update text', () {});
    test('Update text at path', () {});
    test('Update text at node', () {});
    test('Update Node', () {});
    test('Update List of Nodes', () {});
  });

  group('Delete', () {
    test('Delete text', () {});
    test('Delete text at path', () {});
    test('Delete text at node', () {});
    test('Delete Node', () {});
    test('Ensure that needs path computing after deletion', () {});
    test('Delete List of Nodes', () {});
  });

  group('Swap', () {});
}
