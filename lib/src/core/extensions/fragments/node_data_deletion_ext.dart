part of '../../api/document/nodes/node.dart';

@internal
extension NodeDeletionExt on Node {
  @internal
  FragmentChangeContext deleteValueAt(
    int start,
    int len, {
    EasyText? text,
    int fragmentPath = 0,
    int jumpedOffset = 0,
  }) {
    if (isBlockNode || isRootOwner || !hasDefinedValue) {
      return FragmentChangeContext.noExecuted(
          NoExecutionReason.noSatifyConditions);
    }

    assert(len > 0, 'len cannot be less than 1');

    if (supportEmbed) {
      if (hasNoEmbed) {
        return FragmentChangeContext.noExecuted(
          NoExecutionReason.noElement,
        );
      }
      value = null;
      return FragmentChangeContext(
        node: this,
        executed: true,
        changeSize: len,
      );
    }

    final EasyText? frag = text ?? queryFragment(start).cast<EasyText?>();
    if (frag == null) {
      return FragmentChangeContext.noExecuted(isBlankText
          ? NoExecutionReason.noElement
          : NoExecutionReason.invalidStart);
    }

    frag.delete(start, len);
    return FragmentChangeContext(
      node: this,
      executed: true,
      changeSize: len,
    );
  }
}
