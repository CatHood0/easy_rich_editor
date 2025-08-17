part of '../../api/document/nodes/node.dart';

@internal
extension NodeInsertValueModifications on Node {
  @internal
  Node splitLines(
    int start, {
    int linePath = 0,
    int jumpLineOffset = 0,
    int fragmentPath = 0,
    int jumpedOffset = 0,
    bool splitContent = true,
  }) {
    if (!isBlockNode) {
      return this;
    }
    RangeError.checkValidIndex(linePath, children);
    int offset = jumpLineOffset;

    for (int i = linePath; i < length; i++) {
      final Node line = children[i];
      final int currentOffset = offset + line.dataLength;
      if (currentOffset >= start) {
        int localOffset = (start - offset).nonNegative;
        // the split is at the start of the line
        // requires no split of internal values
        final List<TextFragment> left = line.take(
          localOffset,
          splitContent: true,
          jumpedOffset: jumpedOffset.nonNegative,
          fragmentPath: fragmentPath.nonNegative,
        );
        final List<TextFragment> right = line.take(
          localOffset,
          left: false,
          splitContent: true,
          jumpedOffset: jumpedOffset.nonNegative,
          fragmentPath: fragmentPath.nonNegative,
        );
        line.nsValue = <TextFragment>[...left];
        final List<Node> rightLines = children.sublist(i.next.limit(length));
        return Node.block(
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
      }
      offset += line.dataLength;
    }

    return this;
  }

  @internal
  List<TextFragment> take(
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
                ...fragments.sublist(
                    0, i.next.limit(fragments.length)),
              ]
            : <TextFragment>[
                ...fragments
                    .sublist(start == 0 || removedCurrent ? i : i.next.limit(fragments.length)),
              ];
      }
      fragOffset += fragLength;
    }
    return <TextFragment>[...fragments];
  }

  @internal
  FragmentChangeContext insertValueAt(
    Object obj,
    int start, {
    Map<String, dynamic>? attrs,
    int? stringLimitLength,
    int fragmentPath = 0,
    int jumpedOffset = 0,
  }) {
    if (isBlockNode || !hasDefinedValue || isRootOwner) {
      return FragmentChangeContext.noExecuted();
    }

    final List<TextFragment> fragments = value!.castToFragments().toList();
    final bool nodeIsEmpty = fragments.isEmpty;

    if (nodeIsEmpty) {
      fragments.add(
        TextFragment(
          data: obj,
          attributes: attrs,
        ),
      );
      nsValue = <TextFragment>[...fragments];
      return FragmentChangeContext(
        executed: true,
        node: this,
        changeSize: obj.length,
        lastFragmentLength: -1,
        paths: <int>[0],
      );
    }
    RangeError.checkValidIndex(fragmentPath, fragments);
    int fragOffset = jumpedOffset;
    for (int i = fragmentPath; i < fragments.length; i++) {
      final TextFragment fragment = fragments[i];
      final int fragLength = fragment.length;
      final int nextOffset = fragOffset + fragLength;

      if (nextOffset >= start) {
        if (fragment.isEmbedFragment || obj is! String) {
          fragments.insert(
            start == fragOffset ? i.decr.nonNegative : i.next,
            TextFragment(
              data: obj,
              attributes: attrs,
            ),
          );
          nsValue = fragments;
          //FIXME: requires to pass remaining ranges
          // when the stringLimitLength is overlapped by
          // the new text
          return FragmentChangeContext(
            executed: true,
            node: this,
            paths: <int>[start == fragOffset ? i.decr.nonNegative : i.next],
            changeSize: obj.length,
            lastFragmentLength: fragLength,
            remainingRanges: null,
          );
        }
        final FragmentChangeContext result = _tryInsertAtFragmentBoundary(
          fragments: fragments,
          index: i,
          fragment: fragment,
          obj: obj,
          start: start,
          offset: fragOffset,
          fragmentLength: fragLength,
          attrs: attrs,
        );

        if (result.executed) {
          nsValue = <TextFragment>[...fragments];
          //TODO: implement stringLimitLength capabilities
          return result.copyWith();
        }
        return FragmentChangeContext.noExecuted();
      }
      fragOffset += fragLength;
    }

    return FragmentChangeContext.noExecuted();
  }

  FragmentChangeContext _tryInsertAtFragmentBoundary({
    required List<TextFragment> fragments,
    required int index,
    required TextFragment fragment,
    required Object obj,
    required int start,
    required int offset,
    required int fragmentLength,
    Map<String, dynamic>? attrs,
  }) {
    // convert global ranges to local (from global offsets into the list
    // to local range into this TextFragment)
    final String fragText = fragment.getTextValue();

    // if both are zero, means that we are directly
    // in the end of this operation, and must modify or
    // return no execusasation
    fragments[index] = TextFragment(
      data: '${fragText.left(start)}$obj${fragText.right(start)}',
      attributes: attrs ?? fragment.attributes,
    );

    return FragmentChangeContext(
      executed: true,
      changeSize: obj.length,
      node: this,
      lastFragmentLength: fragmentLength,
      remainingRanges: null,
      paths: <int>[index],
    );
  }

  @internal
  FragmentChangeContext deleteValueAt(
    int start,
    int end, {
    int fragmentPath = 0,
    int jumpedOffset = 0,
  }) {
    if (isBlockNode || !hasDefinedValue || isRootOwner) {
      return FragmentChangeContext.noExecuted();
    }

    assert(start != end, 'start and end ranges must be different');

    final List<TextFragment> fragments = value!.castToFragments().toList();
    int offset = jumpedOffset;
    int lengthOfDeletion = end - start;
    int fragPosition = RangeError.checkValidIndex(fragmentPath, fragments);

    int firstAffectedIndex = fragPosition;
    int lastAffectedIndex = fragPosition;

    if (start >= 0 && end >= dataLength) {
      if (start > 0) {
        for (int i = fragPosition; i < value!.castToFragments().length; i++) {
          final TextFragment fragment = fragments[i];
          final Object data = fragment.data;
          final int fragLength = fragment.length;
          final int currentGlobalOffset = offset + fragLength;
          final bool isOutOfRange = currentGlobalOffset <= start;
          if (!isOutOfRange) {
            if (data is! String) {
              fragments.removeAt(i);
              fragPosition = fragPosition.decr.nonNegative;
              nsValue = fragments;
              return FragmentChangeContext(
                executed: true,
                paths: <int>[i],
                changeSize: end - start,
                lastFragmentLength: fragLength,
                node: this,
              );
            }
            final int localStartOffset = (start - offset).nonNegative;

            final String str = data.left(localStartOffset);
            fragments[i] =
                TextFragment(data: str, attributes: fragment.attributes);
            lengthOfDeletion = 0;
            break;
          }
          offset += fragLength;
        }
      }
      nsValue = fragments.sublist(0, fragPosition);
      return FragmentChangeContext(
        executed: true,
        paths: fragPosition.until(fragments.length),
        changeSize: lengthOfDeletion,
        remainingRanges: end == dataLength
            ? null
            : TextRange(
                start: start - lengthOfDeletion,
                end: end - lengthOfDeletion,
              ),
        lastFragmentLength: -1,
        node: this,
      );
    }

    for (int i = fragPosition; i < value!.castToFragments().length; i++) {
      final TextFragment fragment = fragments[i];
      final Object data = fragment.data;
      final int fragLength = fragment.length;
      final int currentGlobalOffset = offset + fragLength;
      offset += fragLength;

      if (lengthOfDeletion <= 0) break;
      // check if we are into the range of the operation that need to be modified
      final bool isOutOfRange = currentGlobalOffset <= start;
      if (isOutOfRange) continue;

      final int localStartOffset = (start - offset).nonNegative;
      final int localEndOffset = (end - offset).nonNegative;

      if (localStartOffset > 0 && localEndOffset <= fragLength) {
        if (data is! String) {
          fragments.removeAt(i);
          fragPosition = fragPosition.decr.nonNegative;
          nsValue = fragments;
          return FragmentChangeContext(
            executed: true,
            paths: <int>[i],
            changeSize: end - start,
            lastFragmentLength: fragLength,
            node: this,
          );
        }

        final String strLeft = data.left(localStartOffset);
        final String strRight = data.right(localEndOffset);
        if (strLeft.isEmpty && strRight.isEmpty) {
          lengthOfDeletion = 0;
          nsValue = fragments;
          return FragmentChangeContext(
            executed: true,
            paths: <int>[i],
            node: this,
          );
        }
        fragments[i] = TextFragment(
            data: '$strLeft$strRight', attributes: fragment.attributes);
        lengthOfDeletion = 0;
        return FragmentChangeContext(
          executed: true,
          paths: <int>[i],
          node: this,
        );
      }

      if (data is! String) {
        lengthOfDeletion--;
        if (lengthOfDeletion <= 0) {
          lastAffectedIndex = i;
          break;
        }
        continue;
      }

      if (localStartOffset > 0 && localEndOffset >= fragLength) {
        final String str = data.left(localStartOffset);
        firstAffectedIndex = i;
        if (str.isEmpty) {
          lengthOfDeletion -= fragLength;
          continue;
        }
        fragments[i] = TextFragment(data: str, attributes: fragment.attributes);
        lengthOfDeletion -= (fragLength - str.length).nonNegative;
        continue;
      }

      if (localEndOffset <= fragLength) {
        final String str = data.right(localEndOffset);
        lastAffectedIndex = i;
        if (str.isEmpty) {
          lengthOfDeletion = 0;
          break;
        }
        fragments[i] = TextFragment(data: str, attributes: fragment.attributes);
        lengthOfDeletion -= (fragLength - str.length).nonNegative;
        break;
      }

      lengthOfDeletion -= fragLength;
    }

    if (lengthOfDeletion <= 0) {
      if (firstAffectedIndex <= -1) {
        throw 'No index was affected during deletion';
      }

      nsValue = <TextFragment>[
        ...fragments.sublist(0, firstAffectedIndex),
        ...fragments.sublist(lastAffectedIndex),
      ];
      return FragmentChangeContext(
        executed: true,
        paths: firstAffectedIndex.until(lastAffectedIndex),
        changeSize: end - start,
        node: this,
      );
    }

    return FragmentChangeContext.noExecuted();
  }
}
