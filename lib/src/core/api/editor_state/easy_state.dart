// ignore_for_file: unused_field

import 'package:easy_rich_editor/easy_rich_editor.dart';
import 'package:easy_rich_editor/src/core/api/selection/remote/remote_selection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill_delta_easy_parser/flutter_quill_delta_easy_parser.dart'
    as pr;
import 'package:flutter_quill_delta_easy_parser/utils/nano_id_generator.dart';
import 'package:meta/meta.dart';

import '../document/history.dart';

class EasyTreeState extends ChangeNotifier {
  EasyDocument document;

  EasyTreeState({required this.document});

  factory EasyTreeState.fromDocument({
    required pr.Document doc,
  }) {
    final Node root = ObjectToNodesParser.documentParse(doc);
    return EasyTreeState(document: EasyDocument(root));
  }

  final ValueNotifier<NodeSelection?> _selectedNodesNotifier =
      ValueNotifier<NodeSelection?>(null);

  final ValueNotifier<List<RemoteSelection>> _remoteSelections =
      ValueNotifier<List<RemoteSelection>>(<RemoteSelection>[]);

  // ========= Getters =========== //
  EasyHistory get changes => document.history;

  static String createNodeId() => '${nanoid(8)}-${nanoid(5)}';

  // ========= Internal Helpers =========== //

  @internal
  void preventNextEventExecution() {}

  // ======= Operations ========== //
}
