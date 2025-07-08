import 'package:easy_rich_editor/internal.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../benchmarks/simple_benchmark.dart';
import '../resources/doc_rs.dart';

void main() {
  final Node root = DocumentToNodesParser.documentParse(largeDoc);
  final Tree tree = Tree(root);

  group('Queries', () {
    test('Query text', () {
      SimpleBenchmark.main(() {
        final Node? node = tree.query("new line 1 [loop - 8000]");
        expect(node, isNotNull);
      });
      SimpleBenchmark.main(() {
        final Node? node = tree.queryPath([3, 0, 0]);
        expect(node, isNotNull);
      });
    });
    test('Query Node', () {});
    test('Query List of Nodes', () {});
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
