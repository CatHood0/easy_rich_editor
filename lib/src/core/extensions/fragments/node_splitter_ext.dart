part of '../../api/document/nodes/node.dart';

@internal
extension NodeSplitterExt on Node {
  @internal
  (Node, MultipleFragmentChangeContext?) splitLines(
    int start, {
    int linePath = 0,
    int jumpLineOffset = 0,
    int fragmentPath = 0,
    int jumpedOffset = 0,
    bool splitContent = true,
  }) {
    if (!isBlockNode) {
      return (this, null);
    }
    RangeError.checkValidIndex(linePath, children);
    int offset = jumpLineOffset;

    for (int i = linePath; i < length; i++) {
      final Node line = children[i];
      final int currentOffset = offset + line.dataLength;
      if (currentOffset > start) {
        int localOffset = (start - offset).nonNegative;
        // the split is at the start of the line
        // requires no split of internal values
        final (
          List<TextFragment> left,
          FragmentChangeContext? leftContext,
        ) = line.takeWithContext(
          localOffset,
          splitContent: true,
          jumpedOffset: jumpedOffset.nonNegative,
          fragmentPath: fragmentPath.nonNegative,
        );
        final (
          List<TextFragment> right,
          FragmentChangeContext? rightContext,
        ) = line.takeWithContext(
          localOffset,
          left: false,
          splitContent: true,
          jumpedOffset: jumpedOffset.nonNegative,
          fragmentPath: fragmentPath.nonNegative,
        );
        line.nsValue = <TextFragment>[...left];
        final List<Node> rightLines = children.sublist(i.next.limit(length));
        final Node nextBlock = Node.block(
          type: type,
          blockAttributes: blockAttributes,
          children: <Node>[
            Node(
              type: line.type,
              value: right,
              canModifyChildrenLength: false,
            ),
            ...rightLines
          ],
          childType: line.type,
        );
        return (
          nextBlock,
          MultipleFragmentChangeContext(
            executed: true,
            changes: <FragmentChangeContext>[
              if (leftContext != null) leftContext,
              if (rightContext != null)
                rightContext.copyWith(node: nextBlock.first),
            ],
          ),
        );
      }
      offset += line.dataLength;
    }

    return (this, null);
  }

  @internal
  (List<TextFragment>, FragmentChangeContext?) takeWithContext(
    int start, {
    bool left = true,
    int fragmentPath = 0,
    int jumpedOffset = 0,
    bool splitContent = true,
  }) {
    if (isBlockNode ||
        !hasDefinedValue ||
        isRootOwner ||
        isBlankOrEmpty ||
        (start == 0 && left || start >= dataLength && !left)) {
      return (<TextFragment>[], null);
    }

    final List<TextFragment> fragments = value!.castToFragments().toList();
    RangeError.checkValidIndex(fragmentPath, fragments);
    int fragOffset = jumpedOffset.nonNegative;
    FragmentChangeContext? context;
    for (int i = fragmentPath; i < fragments.length; i++) {
      final TextFragment fragment = fragments[i];
      final int fragLength = fragment.length;
      final int nextOffset = fragOffset + fragLength;

      if (nextOffset >= start) {
        if (fragment.isEmbedFragment) {
          return (
            left
                ? <TextFragment>[
                    ...fragments.sublist(0, i.next.limit(fragments.length)),
                  ]
                : <TextFragment>[
                    ...fragments.sublist(i.next.limit(fragments.length)),
                  ],
            null
          );
        }
        bool removedCurrent = false;
        if (splitContent) {
          final String fragText = fragment.getTextValue();
          int localStartOffset = (start - fragOffset).nonNegative;
          bool rightAdded = false;

          final String leftT = fragText.left(localStartOffset);
          fragments[i] = TextFragment(
            data: leftT,
            attributes: fragment.attributes,
          );
          final String right = left ? "" : fragText.right(localStartOffset);
          if (right.isNotEmpty && !left) {
            rightAdded = true;
            fragments.insert(
              i.next.limit(fragments.length),
              TextFragment(
                data: right,
                attributes: fragment.attributes,
              ),
            );
          }
          context = FragmentChangeContext(
            executed: true,
            paths: left ? <int>[i] : <int>[...i.until(rightAdded ? i.next : i)],
            node: this,
            changeSize:
                left ? leftT.length : right.length.or(leftT.length, min: 0),
            lastFragmentLength: fragLength,
          );
          if (fragments[i].getTextValue().isEmpty) {
            if (rightAdded) context.paths.removeLast();
            removedCurrent = true;
            fragments.removeAt(i);
          }
        }

        return (
          left
              ? <TextFragment>[
                  ...fragments.sublist(0, i.next.limit(fragments.length)),
                ]
              : <TextFragment>[
                  ...fragments.sublist(start == 0 || removedCurrent
                      ? i
                      : i.next.limit(fragments.length)),
                ],
          context ??
              FragmentChangeContext(
                executed: true,
                paths: <int>[i],
                node: this,
                changeSize: 0,
                lastFragmentLength: fragLength,
              ),
        );
      }
      fragOffset += fragLength;
    }
    return (<TextFragment>[...fragments], null);
  }

  @internal
  List<TextFragment> take(
    int start, {
    bool left = true,
    int fragmentPath = 0,
    int jumpedOffset = 0,
    bool splitContent = true,
  }) {
    if (isBlockNode || !hasDefinedValue || isRootOwner || isBlankOrEmpty) {
      return <TextFragment>[];
    }

    final List<TextFragment> fragments = value!.castToFragments().toList();
    RangeError.checkValidIndex(fragmentPath, fragments);
    int fragOffset = jumpedOffset.nonNegative;
    for (int i = fragmentPath; i < fragments.length; i++) {
      final TextFragment fragment = fragments[i];
      final int fragLength = fragment.length;
      final int nextOffset = fragOffset + fragLength;

      if (nextOffset >= start) {
        if (fragment.isEmbedFragment) {
          return left
              ? <TextFragment>[
                  ...fragments.sublist(0, i.next.limit(fragments.length)),
                ]
              : <TextFragment>[
                  ...fragments.sublist(i.next.limit(fragments.length)),
                ];
        }
        bool removedCurrent = false;
        if (splitContent) {
          final String fragText = fragment.getTextValue();
          int localStartOffset = (start - fragOffset).nonNegative;

          fragments[i] = TextFragment(
            data: fragText.left(localStartOffset),
            attributes: fragment.attributes,
          );
          final String right = fragText.right(localStartOffset);
          if (right.isNotEmpty) {
            fragments.insert(
              i.next.limit(fragments.length),
              TextFragment(
                data: right,
                attributes: fragment.attributes,
              ),
            );
          }
          if (fragments[i].getTextValue().isEmpty) {
            removedCurrent = true;
            fragments.removeAt(i);
          }
        }

        return left
            ? <TextFragment>[
                ...fragments.sublist(0, i.next.limit(fragments.length)),
              ]
            : <TextFragment>[
                ...fragments.sublist(start == 0 || removedCurrent
                    ? i
                    : i.next.limit(fragments.length)),
              ];
      }
      fragOffset += fragLength;
    }
    return <TextFragment>[...fragments];
  }
}
