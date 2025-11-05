part of '../../api/document/nodes/node.dart';

@internal
extension NodeFormattingExt on Node {
  @internal
  OperationResult formatValueAt(
    int start,
    int len,
    EasyAttributeStyles attributes, {
    EasyText? text,
    int fragmentPath = 0,
    int jumpedOffset = 0,
  }) {
    if (isBlockNode || isRootOwner || !hasDefinedValue) {
      return OperationResult.
        noExecuted(NoExecutionReason.noSatifyConditions);
    }

    if (supportEmbed) {
      if (hasNoEmbed) {
        return OperationResult.noExecuted(NoExecutionReason.noElement);
      }
      final TextFragment frag = value.castToFragment();
      if (start >= 0 && len - frag.length <= 0) {
        frag.attributes == null
            ? frag.setAttributes(attributes.toJson()!)
            : frag.mergeAttributes(attributes.toJson()!);
      }
      return OperationResult(
        node: this,
        executed: true,
        changeSize: len,
      );
    }

    final EasyText? frag = text ?? queryObjectAtOffset(start).cast<EasyText?>();
    if (frag == null) {
      return OperationResult.noExecuted(
        isBlankText
            ? NoExecutionReason.noElement
            : NoExecutionReason.invalidStart,
      );
    }

    frag.formatRange(
      start,
      len,
      attributes,
      overrideStylesIfEmpty: true,
    );

    return OperationResult(
      node: this,
      executed: true,
      changeSize: 0,
    );
  }
}
