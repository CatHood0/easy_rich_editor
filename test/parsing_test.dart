import 'package:flutter_quill_delta_easy_parser/flutter_quill_delta_easy_parser.dart';
import 'package:flutter_quill_delta_easy_parser_visualizer/src/parser/document_to_vil_nodes_parser.dart';
import 'package:flutter_test/flutter_test.dart';

import 'resources/doc_rs.dart';

void main() {
  test('', () {
    final doc = commonDoc;

    final root = DocumentToVilNodesParser.parseForRoot(doc);

    print(root.toTreeString());
  });
}
