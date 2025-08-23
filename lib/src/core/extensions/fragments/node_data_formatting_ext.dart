part of '../../api/document/nodes/node.dart';

@internal
extension NodeFormattingExt on Node {
  @internal
  FragmentChangeContext formatValueAt(
    int start,
    int len,
    List<EasyAttribute<dynamic>> attributes, {
    int fragmentPath = 0,
    int jumpedOffset = 0,
  }) {
    if (isBlockNode || !hasDefinedValue || isRootOwner || attributes.isEmpty) {
      return FragmentChangeContext.noExecuted();
    }

    assert(len > 0, 'len cannot be less than 1');

    final List<TextFragment> fragments = <TextFragment>[];
    final int length = this.fragments.length;
    final int end = start + len;
    int offset = jumpedOffset;
    int fragPosition = RangeError.checkValidIndex(fragmentPath, fragments);

    int firstAffectedIndex = -1;
    int lastAffectedIndex = -1;
    int mutableLen = len;
    if (fragPosition > 0) {
      fragments.addAll(this.fragments.sublist(0, fragPosition));
    }

    for (int i = fragPosition; i < length; i++) {
      final TextFragment fragment = this.fragments[i];
      final Object data = fragment.data;
      final int fragLength = fragment.length;
      final int currentGlobalOffset = offset + fragLength;
      if (mutableLen <= 0) {
        fragments.addAll(this.fragments.sublist(i));
        break;
      }

      final int localStartOffset = (start - offset).nonNegative;
      final int localEndOffset = (end - offset).nonNegative;
      offset += fragLength;
      // check if we are into the range of the operation that need to be modified
      if (currentGlobalOffset < start) {
        fragments.add(fragment);
        continue;
      }

      // this means that this fragment is into the range to modify
      // and go out
      if (localStartOffset >= 0 && localEndOffset <= fragLength) {
        if (data is! String ||
            localStartOffset == 0 && localEndOffset == fragLength) {
          fragment.setAttributes(
            attributes
                .toJson(
                  fragment.attributes,
                )
                .nullIfEmpty(),
          );
          nsValue = fragments;
          return FragmentChangeContext(
            executed: true,
            paths: <int>[i],
            changeSize: len,
            lastFragmentLength: fragLength,
            node: this,
          );
        }

        TextFragment strLeft =
            data.left(localStartOffset).toFragment(fragment.attributes);
        TextFragment? middle =
            data.middle(localStartOffset, localEndOffset).toFragment(
                  attributes.toJson(fragment.attributes).nullIfEmpty(),
                );
        TextFragment? strRight =
            data.right(localEndOffset).toFragment(fragment.attributes);

        if (strLeft.canMergeWith(middle)) {
          strLeft = TextFragment(
            data: '${strLeft.data}${middle.data}${strRight.data}',
            attributes: middle.attributes,
          );
          strRight = null;
          middle = null;
        }

        if (strRight != null && strRight.length <= 0) {
          strRight = null;
        }

        nsValue = <TextFragment>[
          ...fragments.sublist(0, i),
          strLeft,
          if (middle != null) middle,
          if (strRight != null) strRight,
          ...fragments.sublist(i.incrIfLess(fragments.length))
        ];
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
        mutableLen--;
        fragment.setAttributes(
            attributes.toJson(fragment.attributes).nullIfEmpty());
        lastAffectedIndex = i;
        if (mutableLen <= 0) {
          lastAffectedIndex = firstAffectedIndex;
          break;
        }
        continue;
      }

      if (localStartOffset > 0) {
        TextFragment strLeft =
            data.left(localStartOffset).toFragment(fragment.attributes);
        TextFragment? strRight = data
            .right(localStartOffset)
            .toFragment(attributes.toJson(fragment.attributes));
        if (strLeft.canMergeWith(strRight)) {
          strLeft = TextFragment(
            data: '${strLeft.data}${strRight.data}',
            attributes: strRight.attributes,
          );
          strRight = null;
          firstAffectedIndex = i;
        }

        if (strRight != null) {
          i.next >= fragment.length
              ? fragments.add(strRight)
              : fragments.insert(i.incr, strRight);
          i = i + 2;
          firstAffectedIndex = i.decr.nonNegative;
        }
        mutableLen -= (fragLength - (strRight ?? strLeft).length).nonNegative;
        continue;
      }

      if (mutableLen - fragLength > 0) {
        final TextFragment? prev = fragments.elementAtOrNull(i.decr);
        if (prev != null && prev.canMergeWith(fragment)) {
          fragments[i.decr] = TextFragment(
            data: '${prev.data}${fragment.data}',
            attributes: prev.attributes,
          );
          fragments.removeAt(i);
          i = i.decr;
          mutableLen -= fragLength;
          continue;
        }
        fragment.setAttributes(attributes.toJson(fragment.attributes));
        lastAffectedIndex = i;
        mutableLen -= fragLength;
        break;
      }

      // where are at the end
      if (mutableLen - fragLength <= 0) {
        if (firstAffectedIndex.isNegative) {
          firstAffectedIndex = i;
        }
        TextFragment strLeft = data
            .left(localEndOffset)
            .toFragment(attributes.toJson(fragment.attributes));
        TextFragment? strRight =
            data.right(localEndOffset).toFragment(fragment.attributes);
        if (strLeft.canMergeWith(strRight)) {
          strLeft = TextFragment(
            data: '${strLeft.data}${strRight.data}',
            attributes: strRight.attributes,
          );
          strRight = null;
          lastAffectedIndex = i;
        }

        if (strRight != null) {
          i.next >= fragment.length
              ? fragments.add(strRight)
              : fragments.insert(i.incr, strRight);
          lastAffectedIndex = i.next;
        }
        mutableLen = 0;
        break;
      }
    }

    nsValue = fragments;
    return FragmentChangeContext(
      executed: true,
      node: deepCopy(),
      paths: <int>[...firstAffectedIndex.until(lastAffectedIndex)],
      changeSize: len,
      remainingRanges: null,
      lastFragmentLength: 0,
    );
  }
}
