part of '../../api/document/nodes/node.dart';

@internal
extension NodeDeletionExt on Node {
  @internal
  OperationResult deleteValueAt(
    int start,
    int len, {
    EasyText? text,
    int fragmentPath = 0,
    int jumpedOffset = 0,
  }) {
    if (isBlockNode || isRootOwner || !hasDefinedValue) {
      return OperationResult.noExecuted(
          NoExecutionReason.noSatifyConditions);
    }

    assert(len > 0, 'len cannot be less than 1');

    if (supportEmbed) {
      if (hasNoEmbed) {
        return OperationResult.noExecuted(
          NoExecutionReason.noElement,
        );
      }
      value = null;
      return OperationResult(
        node: this,
        executed: true,
        changeSize: len,
      );
    }

    final EasyText? frag = text ?? queryObjectAtOffset(start).cast<EasyText?>();
    if (frag == null) {
      return OperationResult.noExecuted(isBlankText
          ? NoExecutionReason.noElement
          : NoExecutionReason.invalidStart);
    }

    frag.delete(start, len);
    return OperationResult(
      node: this,
      executed: true,
      changeSize: len,
    );
  }
}
