import 'package:easy_rich_editor/internal.dart';
import 'package:easy_rich_editor/easy_rich_editor.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../resources/doc_rs.dart';

void main() {
  final Node root = DocumentToNodesParser.documentParse(commonDoc);
  final Tree tree = Tree(root);

  group('Queries', () {
    test('Query Node by id', () {
      const String id = "normal pr 2";
      final Node? node = tree.query(id, deep: false);
      expect(node, isNotNull);
      expect(node!.id, id);
    });
    test('Query Node by full path', () {
      final Node? node = tree.queryPath(<int>[5, 0]);
      expect(node, isNotNull);
    });
    test('Query List of locations by the given text', () {
      final List<NodeValueLocation> locations =
          tree.queryValue("take", caseSensitive: false);
      expect(locations, isNotNull);
      expect(locations, isNotEmpty);
      expect(
        locations.first.location.path,
        <int>[2, 2],
      );
      expect(
        locations.last.location.path,
        <int>[5, 2],
      );
    });
    test('Get the empty line at specified offset', () async {
      final NodeCursorPosLocation location = tree.queryOffset(
        112,
        strict: true,
      );
      expect(location.found, isTrue);
      expect(location.location, isNotNull);
      expect(location.location!.path, isNotEmpty);
      expect(location.location!.path, <int>[3, 0],
          reason: 'Expected: [3,0]. Actual location info: $location');
      expect(location.node!.toPlainText(), equals(''),
          reason: 'Expected: "\\n" was found: ${location.node!.toPlainText()}');
      expect(location.location!.node, tree.queryPath(<int>[3, 0]));
      expect(location.location!.node.type, ParagraphKeys.lineKey);
    });
  });

  group('Add nodes', () {
    test('insert node at start', () {
      final Node node = randomNode;
      tree.addNode(node, after: false, paths: <int>[0]);

      expect(node.parent, isNotNull);
      expect(node.parent, tree.root);
      expect(tree.queryPath(<int>[0]), node);
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
