import 'package:easy_rich_editor/internal.dart';
import 'package:easy_rich_editor/easy_rich_editor.dart';
import 'package:flutter_test/flutter_test.dart';
import '../benchmarks/simple_benchmark.dart';
import '../resources/doc_rs.dart';

void main() {
  final Node root = DocumentToNodesParser.documentParse(commonDoc);
  final Tree tree = Tree(root);

  group('Queries', () {
    test('Query Node by id', () {
      SimpleBenchmark(() {
        final Node? node = tree.query("normal pr 2");
        expect(node, isNotNull);
      }).report();
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
