part of '../../api/document/nodes/node.dart';

extension TextFragmentsModificationsExt on Node {
  @internal
  @protected
  FragmentChangeContext insertValueAt(
    Object obj,
    int start,
    int end, {
    Map<String, dynamic>? attrs,
    int? stringLimitLength,
    int fragmentPath = 0,
  }) {
    if (isBlockNode || !hasDefinedValue || isRootOwner) {
      return FragmentChangeContext.noExecuted();
    }

    assert(start <= end, 'start and end offsets must be normalized');

    // in some cases, if we pass an end that is out this Node (the sibling
    // also will be affected by the range)
    final int outOfBlockEnd = end >= dataLength ? end - dataLength : 0;
    final int contextEnd = outOfBlockEnd > 0 ? dataLength - 1 : end;
    final List<TextFragment> fragments = value!.castToFragments().toList();
    final List<int> paths = <int>[];
    int offset = 0;
    int remainingEnd = end;
    bool insertedElement = false;

    //TODO: make an fast update of the dataLength in this Node
    // and its direct parent to avoid save the time of making
    // two computation when we can just make it here
    for (int i = fragmentPath; i < fragments.length; i++) {
      final TextFragment fragment = fragments[i];
      final int fragLength = fragment.length;
      final int nextOffset = offset + fragLength;

      if (start > offset) {
        offset += fragLength;
        continue;
      }

      // basically, if we are the start and end are into the
      // character range of this Fragment, just make the modification
      if (!insertedElement &&
          _canInsertInFragment(fragment, start, end, offset)) {
        return _handleInsertionInFragment(
          fragments: fragments,
          index: i,
          fragment: fragment,
          obj: obj,
          start: start,
          end: end,
          offset: offset,
          attrs: attrs,
        );
      }

      if (nextOffset > start) {
        if (insertedElement) {
          offset += fragLength;
          continue;
        }

        final FragmentChangeContext result = _tryInsertAtFragmentBoundary(
          fragments: fragments,
          index: i,
          fragment: fragment,
          obj: obj,
          start: start,
          end: end,
          offset: offset,
          remainingEnd: remainingEnd,
          fragmentLength: fragLength,
          attrs: attrs,
        );

        if (result.executed &&
            (result.remainingRanges == null ||
                result.remainingRanges!.end <= 0)) {
          value = <TextFragment>[...fragments];
          return result.copyWith(
            remainingRanges: outOfBlockEnd != 0
                ? TextRange(
                    start: dataLength,
                    end: contextEnd,
                  )
                : null,
          );
        }

        if (start != end) {
          remainingEnd -= fragLength;
        }
        paths.addAll(result.paths);
        insertedElement = true;
        offset += fragLength;
      }
    }

    return FragmentChangeContext.noExecuted();
  }

  bool _canInsertInFragment(
    TextFragment fragment,
    int start,
    int end,
    int offset,
  ) {
    return fragment.isText &&
        fragment.containsOffset(start - offset) &&
        fragment.containsOffset(end - offset);
  }

  FragmentChangeContext _handleInsertionInFragment({
    required List<TextFragment> fragments,
    required int index,
    required TextFragment fragment,
    required Object obj,
    required int start,
    required int end,
    required int offset,
    Map<String, dynamic>? attrs,
  }) {
    final bool isEmbed = obj is! String;
    final int localStart = start - offset;
    final int localEnd = end - offset;
    final String text = fragment.getTextValue();

    if (isEmbed || (attrs != null && !fragment.hasSameAttributes(attrs))) {
      return _splitFragmentForInsertion(
        fragments: fragments,
        index: index,
        fragment: fragment,
        leftText: text.substring(0, localStart),
        insertedContent: obj,
        rightText: text.substring(localEnd),
        attrs: attrs,
      );
    }

    fragments[index] = TextFragment(
      data: '${text.substring(0, localStart)}$obj${text.substring(localEnd)}',
      attributes: fragment.attributes,
    );
    return FragmentChangeContext(executed: true, paths: <int>[index]);
  }

  FragmentChangeContext _splitFragmentForInsertion({
    required List<TextFragment> fragments,
    required int index,
    required TextFragment fragment,
    required String leftText,
    required Object insertedContent,
    required String rightText,
    Map<String, dynamic>? attrs,
  }) {
    fragments[index] =
        TextFragment(data: leftText, attributes: fragment.attributes);

    fragments.insert(
        index + 1, TextFragment(data: insertedContent, attributes: attrs));

    final List<int> paths = <int>[index, index + 1];

    if (rightText.isNotEmpty) {
      final TextFragment rightFrag = TextFragment(
        data: rightText,
        attributes: fragment.attributes,
      );
      fragments.insert(index + 2, rightFrag);
      paths.add(index + 2);
    }

    return FragmentChangeContext(executed: true, paths: paths);
  }

  FragmentChangeContext _tryInsertAtFragmentBoundary({
    required List<TextFragment> fragments,
    required int index,
    required TextFragment fragment,
    required Object obj,
    required int start,
    required int end,
    required int offset,
    required int remainingEnd,
    required int fragmentLength,
    Map<String, dynamic>? attrs,
  }) {
    if (!fragment.isText || obj is! String) {
      fragments.insert(
        index.next,
        TextFragment(
          data: obj,
          attributes: attrs,
        ),
      );
      return FragmentChangeContext(
        executed: true,
        paths: <int>[index.next],
        insertionSize: fragments[index.next].length,
        lastFragmentLength: fragmentLength,
        remainingRanges: (remainingEnd - fragmentLength).nonNegative == 0
            ? null
            : TextRange(
                start: 0,
                end: (remainingEnd - fragmentLength).nonNegative,
              ),
      );
    }

    // convert global ranges to local (from global offsets into the list
    // to local range into this TextFragment)
    final int effectiveStart = (start - offset).nonNegative;
    final int effectiveEnd = (end - offset).nonNegative;
    final int effectiveFragEnd =
        effectiveEnd > fragmentLength ? fragmentLength : effectiveEnd;
    final String text = fragment.getTextValue();
    int effectiveFragmentLength = fragmentLength;

    // if both are zero, means that we are directly
    // in the end of this operation, and must modify or
    // return no execusasation
    if (effectiveStart == effectiveEnd) {
      fragments[index] = TextFragment(
        data: '$text$obj',
        attributes: attrs ?? fragment.attributes,
      );
    } else {
      effectiveFragmentLength -= effectiveFragEnd;
      fragments[index] = TextFragment(
        data: '${text.left(effectiveStart)}$obj${text.right(effectiveFragEnd)}',
        attributes: attrs ?? fragment.attributes,
      );
    }

    return FragmentChangeContext(
      executed: true,
      insertionSize: effectiveFragmentLength,
      lastFragmentLength: fragmentLength,
      remainingRanges: (remainingEnd - effectiveFragEnd).nonNegative == 0
          ? null
          : TextRange(
              start: 0,
              end: (remainingEnd - effectiveFragEnd),
            ),
      paths: <int>[index],
    );
  }
}

@internal
@protected
class FragmentChangeContext {
  final TextRange? remainingRanges;
  final bool executed;
  final NodeDepthPath paths;
  final int insertionSize;
  final int lastFragmentLength;

  const FragmentChangeContext({
    required this.executed,
    required this.paths,
    this.insertionSize = -1,
    this.lastFragmentLength = -1,
    this.remainingRanges,
  });

  const FragmentChangeContext.noExecuted()
      : executed = false,
        insertionSize = -1,
        lastFragmentLength = -1,
        remainingRanges = null,
        paths = const <int>[];

  FragmentChangeContext copyWith({
    TextRange? remainingRanges,
    bool? executed,
    NodeDepthPath? paths,
    int? insertionSize,
    int? lastFragmentLength,
  }) {
    return FragmentChangeContext(
      executed: executed ?? this.executed,
      paths: paths ?? this.paths,
      remainingRanges: remainingRanges ?? this.remainingRanges,
      insertionSize: insertionSize ?? this.insertionSize,
      lastFragmentLength: lastFragmentLength ?? this.lastFragmentLength,
    );
  }
}

extension NonNegativeInt on int {
  int get nonNegative => this < 0 ? 0 : this;
}
