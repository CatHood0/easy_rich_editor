part of '../../api/document/nodes/node.dart';

@internal
extension NodeSplitterExt on Node {
  @internal
  Node? splitLines(
    int start, {
    int linePath = 0,
    EasyText? text,
    int jumpLineOffset = 0,
    int fragmentPath = 0,
    int jumpedOffset = 0,
    bool splitContent = true,
  }) {
    if (!isBlockNode) {
      return null;
    }
    RangeError.checkValidIndex(linePath, children);
    int offset = jumpLineOffset;

    for (int i = linePath; i < length; i++) {
      final Node line = children[i];
      final int currentOffset = offset + line.dataLength;
      if (currentOffset > start) {
        int localOffset = (start - offset).nonNegative;
        final (List<EasyText> left, List<EasyText> right) = line.take(
          localOffset,
          text: text,
          jumpedOffset: jumpedOffset,
          fragmentPath: fragmentPath,
        );
        line.nsValue = EasyTextList()..addAll(left);
        final List<Node> rightLines = children.sublist(i.next.limit(length));
        final Node nextBlock = Node.block(
          type: type,
          blockAttributes: blockAttributes,
          children: <Node>[
            Node(
              type: line.type,
              value: EasyTextList()..addAll(right),
              canModifyChildrenLength: false,
            ),
            ...rightLines
          ],
          childType: line.type,
        );
        return nextBlock;
      }
      offset += line.dataLength;
    }

    return null;
  }

  @internal
  (List<EasyText> left, List<EasyText> right) take(
    int start, {
    EasyText? text,
    int fragmentPath = 0,
    int jumpedOffset = 0,
  }) {
    if (isBlockNode || !hasDefinedValue || isRootOwner || isBlankOrEmpty) {
      return (<EasyText>[], <EasyText>[]);
    }

    int fragOffset = jumpedOffset.nonNegative;
    List<EasyText> left = <EasyText>[];
    List<EasyText> right = <EasyText>[];
    EasyText? efText = text;

    if (efText == null) {
      for (EasyText text in texts) {
        final int fragLength = text.length;
        final int nextOffset = fragOffset + fragLength;

        if (nextOffset >= start) {
          efText = text;
          break;
        }
        fragOffset += fragLength;
        left.add(text);
      }
    }

    assert(
        efText != null,
        'the EasyText fragment must '
        'be defined at this '
        'point. ');
    final String currentId = efText!.id;
    final EasyText? rightText = efText.splitAt(
      (start - fragOffset).nonNegative,
    );
    assert(
        efText.isLinked,
        'was founded '
        'a EasyText instance that '
        'was unlinked from its '
        'parent list');
    left.add(efText);
    efText = rightText != null && rightText.id != currentId
        ? rightText
        : efText.next;
    while (efText != null) {
      right.add(efText);
      efText = efText.next;
    }

    return (left, right);
  }
}
