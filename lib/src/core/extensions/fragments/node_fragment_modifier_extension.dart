part of '../../api/document/nodes/node.dart';

@internal
extension NodeInsertValueModifications on Node {
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
      if (currentOffset >= start) {
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
    FragmentChangeContext? context = null;
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
    int len, {
    int fragmentPath = 0,
    int jumpedOffset = 0,
    bool forward = true,
  }) {
    if (isBlockNode || !hasDefinedValue || isRootOwner) {
      return FragmentChangeContext.noExecuted();
    }

    assert(len > 0, 'len cannot be less than 1');

    final List<TextFragment> fragments = this.fragments.toList();
    int offset = jumpedOffset;
    int fragPosition = RangeError.checkValidIndex(fragmentPath, fragments);

    int firstAffectedIndex = -1;
    int lastAffectedIndex = -1;
    int mutableLen = len;

    for (int i = fragPosition; i < fragments.length; i++) {
      final TextFragment fragment = fragments[i];
      final Object data = fragment.data;
      final int fragLength = fragment.length;
      final int currentGlobalOffset = offset + fragLength;

      // check if we are into the range of the operation that need to be modified
      final bool isOutOfRange = currentGlobalOffset < start;
      print('isOutOfRange: $isOutOfRange');
      print('currentGlobalOffset: $currentGlobalOffset');
      print('frag: $fragment');
      print('offset: $offset');
      final int localStartOffset = (start - offset).nonNegative;
      final int localEndOffset = localStartOffset + len;
      print('Local start: $localStartOffset');
      print('Local end: $localEndOffset');
      if (isOutOfRange) {
        offset += fragLength;
        continue;
      }
      if (mutableLen <= 0) break;

      offset += fragLength;

      // this means that this fragment is into the range to modify
      // and go out
      if (localStartOffset >= 0 && mutableLen - fragLength <= 0) {
        if (data is! String) {
          fragments.removeAt(i);
          nsValue = fragments;
          return FragmentChangeContext(
            executed: true,
            paths: <int>[i],
            changeSize: len,
            lastFragmentLength: fragLength,
            node: this,
          );
        }

        final String strLeft = data.left(localStartOffset);
        final String strRight = data.right(localEndOffset);
        fragments[i] = TextFragment(
          data: '$strLeft$strRight',
          attributes: fragment.attributes,
        );
        if (strLeft.isEmpty && strRight.isEmpty) {
          fragments.removeAt(i);
        }
        nsValue = fragments;
        return FragmentChangeContext(
          executed: true,
          paths: <int>[i],
          changeSize: len,
          lastFragmentLength: fragLength,
          node: this,
        );
      }

      if (data is! String) {
        if (firstAffectedIndex.isNegative) {
          // to avoid include this one
          firstAffectedIndex = i.decr;
        }
        lastAffectedIndex = i;
        mutableLen--;
        if (mutableLen <= 0) {
          lastAffectedIndex = firstAffectedIndex;
          break;
        }
        continue;
      }

      //FIXME: we need to check if the str is empty
      // and remove that fragment
      if (localStartOffset > 0) {
        final String str = data.left(localStartOffset);
        firstAffectedIndex = i;
        fragments[i] = TextFragment(data: str, attributes: fragment.attributes);
        mutableLen -= (fragLength - str.length).nonNegative;
        continue;
      }

      // where are at the end
      if (mutableLen - fragLength <= 0) {
        if (firstAffectedIndex.isNegative) {
          firstAffectedIndex = i;
        }
        final String str = data.right(
          forward ? localEndOffset.next.limit(data.length) : localEndOffset,
        );
        lastAffectedIndex = i;
        if (str.isEmpty) {
          mutableLen = 0;
          break;
        }
        fragments[i] = TextFragment(data: str, attributes: fragment.attributes);
        mutableLen -= (fragLength - str.length).nonNegative;
        break;
      }

      lastAffectedIndex = i;
      mutableLen -= fragLength;
    }

    if (mutableLen.nonNegative == 0) {
      if (lastAffectedIndex.isNegative) {
        throw 'No index was affected during deletion. len: $mutableLen, Fragments: $fragments';
      }

      nsValue = <TextFragment>[
        // if firstAffectedIndex is equals than
        // lastAffectedIndex this means that
        // we are removing something entirely
        //
        // tipically, this occurs just with embeds
        if (firstAffectedIndex < lastAffectedIndex)
          ...fragments.sublist(
            0,
            firstAffectedIndex.next.limit(fragments.length).or(0),
          ),
        // avoid adding a duplicated fragment
        if (lastAffectedIndex > firstAffectedIndex)
          ...fragments.sublist(lastAffectedIndex),
      ];
      return FragmentChangeContext(
        executed: true,
        paths: firstAffectedIndex.nonNegative.until(lastAffectedIndex),
        // make more precise the change of the size
        changeSize: len,
        node: this,
      );
    }
    return FragmentChangeContext.noExecuted();
  }
}

    // if (start >= 0 && len >= dataLength) {
    //   int position = -1;
    //   if (start > 0) {
    //     for (int i = fragPosition; i < fragments.length; i++) {
    //       final TextFragment fragment = fragments[i];
    //       final Object data = fragment.data;
    //       final int fragLength = fragment.length;
    //       final int currentGlobalOffset = offset + fragLength;
    //       final bool isOutOfRange = currentGlobalOffset <= start;
    //       if (isOutOfRange) {
    //         offset += fragLength;
    //         continue;
    //       }
    //       position = i;
    //       if (data is! String) {
    //         position = i.decr;
    //         break;
    //       }
    //       final String str = data.left((start - offset).nonNegative);
    //       if (str.isEmpty) {
    //         position = i.decr;
    //         break;
    //       }
    //       fragments[i] = TextFragment(
    //         data: str,
    //         attributes: fragment.attributes,
    //       );
    //       break;
    //     }
    //   }
    //   nsValue = position <= -1
    //       ? <TextFragment>[]
    //       : fragments.sublist(
    //           0,
    //           position.next.limit(
    //             fragments.length,
    //           ));
    //   return FragmentChangeContext(
    //     executed: true,
    //     paths: <int>[
    //       ...position.or(fragPosition).until(
    //             fragments.length,
    //           ),
    //     ],
    //     changeSize: dataLength - start,
    //     node: this,
    //   );
    // }
