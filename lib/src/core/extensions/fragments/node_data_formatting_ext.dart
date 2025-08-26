part of '../../api/document/nodes/node.dart';

@internal
extension NodeFormattingExt on Node {
  //TODO: we need to check if works correctly
  // with adjacent attributes applications
  @internal
  void formatValueAt(
    int start,
    int len,
    EasyAttributeStyles attributes, {
    EasyText? text,
    int fragmentPath = 0,
    int jumpedOffset = 0,
  }) {
    if (isBlockNode || !hasDefinedValue || isRootOwner || attributes.isEmpty) {
      return;
    }

    assert(len > 0, 'len cannot be less than 1');
  }
}
