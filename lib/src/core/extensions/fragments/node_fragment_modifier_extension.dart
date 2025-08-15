part of '../../api/document/nodes/node.dart';

@internal
extension NodeInsertValueModifications on Node {
  @internal
  FragmentChangeContext insertValueWithContextAt(
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
    int offset = jumpedOffset;
    _computeNewCacheValues(
      fragments,
      nodeIsEmpty,
      start,
      obj,
    );

    if (nodeIsEmpty) {
      fragments.add(
        TextFragment(
          data: obj,
          attributes: attrs,
        ),
      );
      value = <TextFragment>[...fragments];
      return FragmentChangeContext(
        executed: true,
        node: this,
        insertionSize: obj.length,
        lastFragmentLength: 0,
        paths: <int>[0],
      );
    }
    for (int i = fragmentPath; i < fragments.length; i++) {
      final TextFragment fragment = fragments[i];
      final int fragLength = fragment.length;
      final int nextOffset = offset + fragLength;
      offset += fragLength;

      if (nextOffset >= start) {
        final FragmentChangeContext result = _tryInsertAtFragmentBoundary(
          fragments: fragments,
          index: i,
          fragment: fragment,
          obj: obj,
          start: start,
          offset: offset,
          fragmentLength: fragLength,
          attrs: attrs,
        );

        if (result.executed) {
          value = <TextFragment>[...fragments];
          //TODO: implement stringLimitLength capabilities
          return result.copyWith();
        }
      }
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
    if (fragment.isEmbedFragment || obj is! String) {
      fragments.insert(
        index.next,
        TextFragment(
          data: obj,
          attributes: attrs,
        ),
      );
      return FragmentChangeContext(
        executed: true,
        node: this,
        paths: <int>[index.next],
        insertionSize: fragments[index.next].length,
        lastFragmentLength: fragmentLength,
        //FIXME: requires to pass remaining ranges
        // when the stringLimitLength is overlapped by
        // the new text
        remainingRanges: null,
      );
    }

    // convert global ranges to local (from global offsets into the list
    // to local range into this TextFragment)
    final String text = fragment.getTextValue();

    // if both are zero, means that we are directly
    // in the end of this operation, and must modify or
    // return no execusasation
    fragments[index] = TextFragment(
      data: '${text.left(start)}$obj${text.right(start)}',
      attributes: attrs ?? fragment.attributes,
    );

    return FragmentChangeContext(
      executed: true,
      insertionSize: obj.length,
      node: this,
      lastFragmentLength: fragmentLength,
      remainingRanges: null,
      paths: <int>[index],
    );
  }

  void _computeNewCacheValues(
    List<TextFragment> fragments,
    bool nodeIsEmpty,
    int start,
    Object obj,
  ) {
    int? oldParentLength = parent?._dataLength != null && nodeIsEmpty
        ? parent!._dataLength!.toInt() - 1
        : parent?._dataLength;
    int? oldDataLength = _dataLength != null && nodeIsEmpty ? 0 : _dataLength;
    String? oldParentText = parent?._text;
    String? oldText = _text;
    // normally, when a node with values is empty
    // means that this is a new line and manually we set
    // a length of 1 to let to the editor think
    // that we are really in a new line
    _dataLength = fragments.isEmpty ? obj.length : dataLength + obj.length;
    parent?.invalidateDataOffset();
    if (oldParentLength != null && oldDataLength != null) {
      parent?._dataLength = (oldParentLength - oldDataLength) + _dataLength!;
    }
    if (oldParentText != null) {
      parent!._text = oldParentText.replaceRange(
        start,
        start,
        obj.text(),
      );
    }
    if (oldText != null) {
      _text = oldText.replaceRange(
        start,
        start,
        obj.text(),
      );
    }
  }
}

extension NonNegativeInt on int {
  int get nonNegative => this < 0 ? 0 : this;
}

extension on int? {
  int? operator +(int other) {
    return this == null ? other : this + other;
  }
}
