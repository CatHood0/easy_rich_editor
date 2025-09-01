part of '../../api/document/nodes/node.dart';

@internal
extension NodeFormattingExt on Node {
  @internal
  FragmentChangeContext formatValueAt(
    int start,
    int len,
    EasyAttributeStyles attributes, {
    EasyText? text,
    int fragmentPath = 0,
    int jumpedOffset = 0,
  }) {
    if (isBlockNode || isRootOwner || !hasDefinedValue) {
      return FragmentChangeContext.noExecuted(
          NoExecutionReason.noSatifyConditions);
    }

    if (supportEmbed) {
      if (hasNoEmbed) {
        return FragmentChangeContext.noExecuted(NoExecutionReason.noElement);
      }
      final TextFragment frag = value.castToFragment();
      if (start >= 0 && len - frag.length <= 0) {
        frag.attributes == null
            ? frag.setAttributes(attributes.toJson()!)
            : frag.mergeAttributes(attributes.toJson()!);
      }
      return FragmentChangeContext(
        node: this,
        executed: true,
        changeSize: len,
      );
    }

    final EasyText? frag = text ?? queryObjectAtOffset(start).cast<EasyText?>();
    if (frag == null) {
      return FragmentChangeContext.noExecuted(
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

    return FragmentChangeContext(
      node: this,
      executed: true,
      changeSize: 0,
    );
  }
}
