part of '../../api/document/nodes/node.dart';

@internal
extension NodeInsertionExt on Node {
  @internal
  OperationResult insertValueAt(
    Object obj,
    int start, {
    EasyText? text,
    EasyAttributeStyles? styles,
    int? stringLimitLength,
    int fragmentPath = 0,
    int jumpedOffset = 0,
  }) {
    if (isBlockNode || isRootOwner || !hasDefinedValue) {
      return OperationResult.noExecuted(
          NoExecutionReason.noSatifyConditions);
    }

    if (supportEmbed && obj is! String) {
      assert(
        hasNoEmbed,
        '${shortInfo()} must have '
        'no defined value to '
        'insert something',
      );
      final TextFragment frag = TextFragment(
        data: obj,
        attributes: styles?.toJson(),
      );
      value = frag;
      dataLength = 1;
      return OperationResult(
        node: this,
        executed: true,
        changeSize: obj.length,
      );
    }

    assert(
      obj is String,
      '$obj must be a '
      'string to be inserted '
      'in a node that '
      'supports only EasyText',
    );

    final EasyText? frag = text ?? queryObjectAtOffset(start).cast<EasyText?>();
    if (frag == null) {
      return OperationResult.noExecuted(
        isBlankText
            ? NoExecutionReason.noElement
            : NoExecutionReason.invalidStart,
      );
    }

    frag.insert(
      start,
      obj.castString(),
      styles,
    );
    return OperationResult(
      node: this,
      executed: true,
      changeSize: obj.length,
    );
  }
}
