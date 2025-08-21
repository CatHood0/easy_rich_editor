import 'package:easy_rich_editor/src/core/api/document/path/path.dart';
import 'package:easy_rich_editor/src/core/extensions/object_ext.dart';

import '../../../../easy_rich_editor.dart';

abstract class EasyOperation {
  final NodeDepthPath path;
  final Node node;

  EasyOperation({
    required this.path,
    required this.node,
  });

  EasyOperation invert();
}

class EasyFormatOperation extends EasyOperation {
  final Map<String, dynamic>? attributes;
  final Map<String, dynamic>? oldAttributes;
  final int cursorPosition;
  final int len;

  EasyFormatOperation({
    required super.path,
    required super.node,
    required this.cursorPosition,
    required this.len,
    required this.attributes,
    required this.oldAttributes,
  });

  @override
  EasyFormatOperation invert() {
    return EasyFormatOperation(
      path: path,
      node: node,
      len: len,
      attributes: oldAttributes,
      oldAttributes: attributes,
      cursorPosition: cursorPosition,
    );
  }
}

class EasyInsertOperation extends EasyOperation {
  final Object data;
  final Map<String, dynamic>? attributes;
  final int cursorPosition;

  EasyInsertOperation({
    required super.path,
    required super.node,
    required this.data,
    required this.cursorPosition,
    this.attributes,
  });

  @override
  EasyDeleteOperation invert() {
    return EasyDeleteOperation(
      path: path,
      node: node,
      len: data.length,
      forward: false,
      cursorPosition: cursorPosition,
    );
  }
}

class EasyDeleteOperation extends EasyOperation {
  // a copy of these nodes that we need
  // to reinsert then when removed
  final List<Node>? affectedNodes;
  final int cursorPosition;
  final int len;
  final Object? deletedContent;
  final bool forward;

  EasyDeleteOperation({
    required super.path,
    required super.node,
    required this.cursorPosition,
    required this.len,
    this.affectedNodes,
    this.forward = false,
    this.deletedContent,
  });

  @override
  EasyInsertOperation invert() {
    return EasyInsertOperation(
      path: path,
      node: node,
      data: deletedContent ?? '',
      cursorPosition: cursorPosition,
    );
  }
}
