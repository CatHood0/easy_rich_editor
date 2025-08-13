import 'package:easy_rich_editor/easy_rich_editor.dart';
import 'package:easy_rich_editor/src/core/api/document/changes/fragment_change_context.dart';
import 'package:easy_rich_editor/src/core/logger/configs/easy_logger_configurations.dart';
import 'package:easy_rich_editor/src/core/logger/editor_logger.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import '../resources/doc_rs.dart';

void main() {
  final Node root = DocumentToNodesParser.documentParse(commonDoc);
  test('insertText', () {
    debugPrint(
      root.queryPath(<int>[2, 0])!.dumpTreeStr(
        currentPath: <int>[2, 0],
      ),
    );
    final EasyLoggerConfiguration config = EasyLoggerConfiguration()
      ..level = EasyLogLevel.all
      ..handler = (String message) {
        print(message);
      };
    final FragmentChangeContext context = root.insert(
      50,
      'My text',
    );
    debugPrint(
      root.dumpTreeStr(
        currentPath: <int>[2, 0],
      ),
    );
  });
  test('insertNode', () {});
}
