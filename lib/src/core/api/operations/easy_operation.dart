import 'package:easy_attribution_text/easy_text.dart';
import 'package:easy_rich_editor/src/core/api/document/path/path.dart';
import 'package:easy_rich_editor/src/core/extensions/object_ext.dart';

import '../../../../easy_rich_editor.dart';

abstract class EasyOperation {
  /// The selection to be applied after usage of this operation
  final NodeSelection? nextSelection;

  /// The selection to be applied if the operation
  /// is inverted usage of this operation
  final NodeSelection? previousSelection;
  final NodeDepthPath path;

  /// A copy of the node
  final Node node;

  EasyOperation({
    required this.path,
    required this.node,
    this.nextSelection,
    this.previousSelection,
  });

  /// The id that represents the operation
  String get id;

  EasyOperation invert();

  DeltaNode toDelta();

  Map<String, dynamic> toJson();
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
    super.nextSelection,
    super.previousSelection,
  });

  @override
  String get id => 'format';

  @override
  EasyFormatOperation invert() {
    return EasyFormatOperation(
      path: path,
      node: node,
      len: len,
      attributes: oldAttributes,
      oldAttributes: attributes,
      cursorPosition: cursorPosition,
      nextSelection: nextSelection,
      previousSelection: previousSelection,
    );
  }

  @override
  DeltaNode toDelta() {
    assert(!node.isRootOwner, 'root node must not be stored as a node change');
    final EasyAttributeStyles styles = EasyAttributeStyles.fromJson(attributes);
    return DeltaNode.format(
      styles: styles,
      len: len,
      start: cursorPosition,
      inlineStyles: styles.values.every(
        (EasyAttribute<Object?> e) => e.isInline,
      ),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'path': path,
      'node': node,
      'len': len,
      'attributes': oldAttributes,
      'oldAttributes': attributes,
      'cursorPosition': cursorPosition,
    };
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
    super.nextSelection,
    super.previousSelection,
  });

  @override
  String get id => 'insertion';

  @override
  EasyDeleteOperation invert() {
    return EasyDeleteOperation(
      path: path,
      node: node,
      len: data.length,
      forward: false,
      cursorPosition: cursorPosition,
      nextSelection: nextSelection,
      previousSelection: previousSelection,
    );
  }

  @override
  DeltaNode toDelta() {
    return DeltaNode.insert(
      start: cursorPosition,
      insert: data,
      styles: EasyAttributeStyles.fromJson(attributes),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'path': path,
      'node': node,
      'len': data.length,
      'cursorPosition': cursorPosition,
      'attributes': attributes,
    };
  }
}

class EasyDeleteOperation extends EasyOperation {
  final int cursorPosition;
  final int len;
  final Object? deletedContent;
  final bool forward;

  EasyDeleteOperation({
    required super.path,
    required super.node,
    required this.cursorPosition,
    required this.len,
    this.forward = false,
    this.deletedContent,
    super.nextSelection,
    super.previousSelection,
  });

  @override
  String get id => 'deletion';

  @override
  EasyInsertOperation invert() {
    return EasyInsertOperation(
      path: path,
      node: node,
      data: deletedContent!,
      cursorPosition: cursorPosition,
      nextSelection: nextSelection,
      previousSelection: previousSelection,
    );
  }

  @override
  DeltaNode toDelta() {
    if (deletedContent != null) {
      return DeltaNode.replace(
        inserted: deletedContent,
        start: cursorPosition,
        len: len,
      );
    }
    return DeltaNode.delete(
      start: cursorPosition,
      len: len,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'path': path,
      'node': node,
      'len': len,
      'forward': forward,
      'removed': deletedContent,
      'cursorPosition': cursorPosition,
    };
  }
}
