part of '../../api/document/nodes/node.dart';

@internal
extension NodeDeletionExt on Node {
  @internal
  FragmentChangeContext deleteValueAt(
    int start,
    int len, {
    int fragmentPath = 0,
    int jumpedOffset = 0,
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
      final int localStartOffset = (start - offset).nonNegative;
      final int localEndOffset = localStartOffset + len;
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
        final String str = data.right(localEndOffset);
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
