// ignore_for_file: unused_field

import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:easy_rich_editor/easy_rich_editor.dart';
import 'package:easy_rich_editor/src/core/api/selection/remote/remote_selection.dart';
import 'package:easy_rich_editor/src/core/parser/plain_text_to_nodes_parser.dart';
import 'package:easy_rich_editor/src/tree_manager/tree.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill_delta_easy_parser/flutter_quill_delta_easy_parser.dart'
    as pr;
import 'package:flutter_quill_delta_easy_parser/utils/nano_id_generator.dart';
import 'package:meta/meta.dart';

class EasyTreeState extends ChangeNotifier {
  Tree _tree;

  EasyTreeState({
    required Node root,
  }) : _tree = Tree(root);

  factory EasyTreeState.fromDocument({
    required pr.Document doc,
  }) {
    final Node root = DocumentToNodesParser.documentParse(doc);
    return EasyTreeState(root: root);
  }

  factory EasyTreeState.fromMarkdown({required String text}) {
    final Node root = DocumentToNodesParser.markdownParse(text);
    return EasyTreeState(root: root);
  }

  factory EasyTreeState.fromPlainText({required String text}) {
    final Node root = PlainTextToNodesParser.parse(text: text);
    return EasyTreeState(root: root);
  }

  factory EasyTreeState.fromDelta({required Delta delta}) {
    final Node root = DocumentToNodesParser.deltaParse(delta);
    return EasyTreeState(root: root);
  }

  final ValueNotifier<NodeSelection?> _selectedNodesNotifier =
      ValueNotifier<NodeSelection?>(null);

  final ValueNotifier<List<RemoteSelection>> _remoteSelections =
      ValueNotifier<List<RemoteSelection>>(<RemoteSelection>[]);

  // ========= Getters =========== //
  Node get root => _tree.root;

  FixedListLength get changes => _tree.changes;

  static String createNodeId() => nanoid(8);

  // ========= Internal Helpers =========== //

  @internal
  void preventNextEventExecution() {}

  // ======= Operations ========== //
}
