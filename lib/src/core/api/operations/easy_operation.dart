import 'package:easy_attribution_text/easy_text.dart';
import 'package:easy_rich_editor/src/core/extensions/object_ext.dart';
import '../../../../easy_rich_editor.dart';

abstract class EasyOperation {
  /// Whether this operation comes from remote editor
  final bool isRemote;
  final NodeSelection selection;
  final OperationMetadata metadata;

  EasyOperation({
    required this.selection,
    required this.metadata,
    this.isRemote = false,
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

  EasyFormatOperation({
    required this.attributes,
    required this.oldAttributes,
    required super.selection,
    required super.metadata,
  });

  @override
  String get id => 'format';

  @override
  EasyFormatOperation invert() {
    return EasyFormatOperation(
        attributes: oldAttributes,
        oldAttributes: attributes,
        selection: selection,
        metadata: metadata);
  }

  @override
  DeltaNode toDelta() {
    final EasyAttributeStyles styles = EasyAttributeStyles.fromJson(attributes);
    return DeltaNode.format(
      styles: styles,
      selection: selection,
      inlineStyles: styles.values.every(
        (EasyAttribute<Object?> e) => e.isInline,
      ),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'selection': selection,
      'attributes': oldAttributes,
      'oldAttributes': attributes,
    };
  }
}

class EasyInsertOperation extends EasyOperation {
  final Object data;
  final EasyAttributeStyles? attributes;

  EasyInsertOperation({
    required super.selection,
    required super.metadata,
    required this.data,
    this.attributes,
  });

  @override
  String get id => 'insertion';

  @override
  EasyDeleteOperation invert() {
    return EasyDeleteOperation(
      metadata: metadata,
      deletedContent: data,
      contentAttrs: attributes?.toJson() ?? <String, dynamic>{},
      forward: false,
      selection: selection,
    );
  }

  @override
  DeltaNode toDelta() {
    return DeltaNode.insert(
      insert: data,
      selection: selection,
      styles: attributes ?? EasyAttributeStyles.empty(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'len': data.length,
      'attributes': attributes,
    };
  }
}

class EasyDeleteOperation extends EasyOperation {
  final Object? deletedContent;
  final Map<String, dynamic> contentAttrs;
  final bool forward;

  EasyDeleteOperation({
    required super.selection,
    required super.metadata,
    this.contentAttrs = const <String, dynamic>{},
    this.forward = false,
    this.deletedContent,
  });

  @override
  String get id => 'deletion';

  @override
  EasyInsertOperation invert() {
    return EasyInsertOperation(
      data: deletedContent!,
      metadata: metadata,
      selection: selection,
      attributes: EasyAttributeStyles.fromJson(
        contentAttrs,
      ),
    );
  }

  @override
  DeltaNode toDelta() {
    if (deletedContent != null) {
      return DeltaNode.replace(
        data: deletedContent!,
        selection: selection,
      );
    }
    return DeltaNode.delete(
      selection: selection,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'metadata': metadata,
      'selection': selection,
      'forward': forward,
      'removed': deletedContent,
    };
  }
}

class OperationMetadata {
  /// Represents the old state of a node
  ///
  /// Tipically used when require retrieving the state
  /// of a removed node
  final Map<String, dynamic> oldState;

  OperationMetadata({
    required this.oldState,
  });
}
