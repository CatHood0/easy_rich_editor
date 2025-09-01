import 'package:easy_attribution_text/easy_text.dart';
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

  DeltaNode toDelta();
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

  @override
  DeltaNode toDelta() {
    assert(!node.isRootOwner, 'root node must not be stored as a node change');
    final bool isSelectinEntireBlock =
        cursorPosition == 0 && cursorPosition + len == node.dataLength;
    return DeltaNode.format(
      len: len,
      start: cursorPosition,
      styles: EasyAttributeStyles.fromJson(attributes),
      inlineStyles: !isSelectinEntireBlock || !node.isBlockNode,
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

  @override
  DeltaNode toDelta() {
    return DeltaNode.insert(
      insert: data,
      start: cursorPosition,
      styles: EasyAttributeStyles.fromJson(attributes),
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

  @override
  DeltaNode toDelta() {
    if (affectedNodes != null && affectedNodes!.isNotEmpty) {
      EasyEditorLogger.operations.debug('Cannot be returned a '
          'correct DeltaNode struct when there are '
          'registered more than one affected '
          'node => $affectedNodes');
      return DeltaNode.invalid();
    }
    if (deletedContent != null) {
      return DeltaNode.replace(
        inserted: deletedContent,
        start: cursorPosition,
        end: cursorPosition + len,
      );
    }
    return DeltaNode.delete(
      start: cursorPosition,
      end: cursorPosition + len,
    );
  }
}
