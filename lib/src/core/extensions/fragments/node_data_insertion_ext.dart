part of '../../api/document/nodes/node.dart';

@internal
extension NodeInsertionExt on Node {
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
}
