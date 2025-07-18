import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:easy_rich_editor/easy_rich_editor.dart';
import 'package:easy_rich_editor/src/core/parser/plain_text_to_nodes_parser.dart';
import 'package:easy_rich_editor/src/tree_manager/tree.dart';
import 'package:flutter_quill_delta_easy_parser/flutter_quill_delta_easy_parser.dart';

class EasyState {
  Tree _tree;

  EasyState({required Node root}) : _tree = Tree(root);

  factory EasyState.fromDocument({
    required Document doc,
  }) {
    final Node root = DocumentToNodesParser.documentParse(doc);
    return EasyState(root: root);
  }

  factory EasyState.fromMarkdown({required String text}) {
    final Node root = DocumentToNodesParser.markdownParse(text);
    return EasyState(root: root);
  }

  factory EasyState.fromPlainText({required String text}) {
    final Node root = PlainTextToNodesParser.parse(text: text);
    return EasyState(root: root);
  }

  factory EasyState.fromDelta({required Delta delta}) {
    final Node root = DocumentToNodesParser.deltaParse(delta);
    return EasyState(root: root);
  }

  // ========= Getters =========== //

  Node get root => _tree.root;
  // ========= Internal Helpers =========== //

  // ======= Operations ========== //
}
