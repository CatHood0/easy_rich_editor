import 'package:flutter_quill_delta_easy_parser/flutter_quill_delta_easy_parser.dart';
import '../../../../../easy_rich_editor.dart';

class EasyOperation {
  final String type;

  // This must be a copy of the original object
  final Node? targetChange;
  final TextFragment? data;
  final Map<String, dynamic>? metadataChange;
  final int startOffset;
  final int? endOffset;

  /// Only defined when `type` is equals to `moveKey`
  // both of the class locations must have copies
  // of the original objects
  final NodeLocation? moveFrom;
  final NodeLocation? moveTo;

  EasyOperation({
    required this.type,
    required this.startOffset,
    this.targetChange,
    this.moveFrom,
    this.moveTo,
    this.data,
    this.endOffset,
    this.metadataChange,
  });

  EasyOperation.delete({
    required this.startOffset,
    required this.endOffset,
    required this.targetChange,
  })  : data = null,
        moveFrom = null,
        moveTo = null,
        metadataChange = null,
        type = deleteKey;

  EasyOperation.ignore({
    required this.startOffset,
    required this.endOffset,
  })  : data = null,
        targetChange = null,
        moveFrom = null,
        moveTo = null,
        metadataChange = null,
        type = ignoreKey;

  EasyOperation.insert({
    required this.startOffset,
    required this.targetChange,
    required this.data,
  })  : moveFrom = null,
        moveTo = null,
        endOffset = null,
        metadataChange = null,
        type = insertKey;

  /// Update is only used when a change in
  /// the attributes of a node is applied
  EasyOperation.update({
    required this.startOffset,
    required this.endOffset,
    required this.targetChange,
    this.metadataChange,
  })  : moveFrom = null,
        data = null,
        moveTo = null,
        type = updateKey;

  /// Move is only used when we moves
  /// a nodes to another place from its
  /// original position
  EasyOperation.move({
    required this.moveFrom,
    required this.moveTo,
    required this.targetChange,
  })  : data = null,
        startOffset = -1,
        endOffset = null,
        metadataChange = null,
        type = moveKey;

  bool get isInsert => type == insertKey;
  bool get isDelete => type == deleteKey;
  bool get isIgnore => type == ignoreKey;
  bool get isUpdate => type == updateKey;
  bool get isMove => type == moveKey;

  static const String deleteKey = 'delete';
  static const String insertKey = 'insert';
  static const String updateKey = 'update';
  static const String ignoreKey = 'ignore';
  static const String moveKey = 'move';
}
