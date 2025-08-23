part of '../../api/document/nodes/node.dart';

@internal
extension NodeFormattingExt on Node {
  //TODO: we need to check if works correctly
  // with adjacent attributes applications
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

    final List<TextFragment> newFragments = <TextFragment>[];
    final int totalFragments = fragments.length;
    final int end = start + len;
    int currentOffset = jumpedOffset;

    RangeError.checkValidIndex(fragmentPath, fragments);

    if (fragmentPath > 0) {
      newFragments.addAll(fragments.sublist(0, fragmentPath));
    }

    List<int> affectedIndices = <int>[];
    bool mergeLeft = false;
    bool mergeRight = false;

    for (int i = fragmentPath; i < totalFragments; i++) {
      final TextFragment fragment = fragments[i];
      final int fragLength = fragment.length;
      final int fragmentEnd = currentOffset + fragLength;

      if (fragmentEnd <= start) {
        newFragments.add(fragment);
        currentOffset += fragLength;
        continue;
      }

      if (currentOffset >= end) {
        newFragments.add(fragment);
        currentOffset += fragLength;
        continue;
      }

      affectedIndices.add(i);
      final Map<String, dynamic> newAttributes =
          attributes.toJson(fragment.attributes);

      final int localStart = (start - currentOffset).clamp(0, fragLength);
      final int localEnd = (end - currentOffset).clamp(0, fragLength);

      // Split fragments if required 
      if (localStart > 0 || localEnd < fragLength) {
        _splitFragmentWithMergeCheck(newFragments, fragment, localStart,
            localEnd, newAttributes, currentOffset);

        // Mark possible new merge candidates 
        mergeLeft = (localStart > 0);
        mergeRight = (localEnd < fragLength);
      } else {
        newFragments.add(TextFragment(
          data: fragment.data,
          attributes: newAttributes,
        ));

        mergeLeft = true;
        mergeRight = true;
      }

      currentOffset += fragLength;
      if (currentOffset >= end) break;
    }

    // Incremental merge - Only apply merging where there are changes 
    if (mergeLeft && newFragments.length > 1) {
      _tryMergeWithPrevious(newFragments, newFragments.length - 1);
    }

    // Approach merging 
    if (affectedIndices.isNotEmpty) {
      final int lastAffected = affectedIndices.last;
      if (lastAffected + 1 < totalFragments) {
        for (int i = lastAffected + 1; i < totalFragments; i++) {
          newFragments.add(fragments[i]);
          if (mergeRight) {
            _tryMergeWithPrevious(newFragments, newFragments.length - 1);
          }
        }
      }
    }

    nsValue = newFragments;

    return FragmentChangeContext(
      executed: true,
      paths: affectedIndices,
      changeSize: len,
      lastFragmentLength: newFragments.lastOrNull?.length ?? 0,
      node: this,
    );
  }

  void _splitFragmentWithMergeCheck(
    List<TextFragment> result,
    TextFragment fragment,
    int start,
    int end,
    Map<String, dynamic> newAttributes,
    int baseOffset,
  ) {
    if (fragment.data is! String) {
      result.add(TextFragment(
        data: fragment.data,
        attributes: newAttributes,
      ));
      return;
    }

    final String text = fragment.data as String;
    TextFragment? leftPart;
    TextFragment? middlePart;
    TextFragment? rightPart;

    if (start > 0) {
      leftPart = TextFragment(
        data: text.substring(0, start),
        attributes: fragment.attributes,
      );
    }

    if (end > start) {
      middlePart = TextFragment(
        data: text.substring(start, end),
        attributes: newAttributes,
      );
    }

    if (end < text.length) {
      rightPart = TextFragment(
        data: text.substring(end),
        attributes: fragment.attributes,
      );
    }

    if (leftPart != null) {
      if (result.isNotEmpty && result.last.shouldMerge(leftPart)) {
        result[result.length - 1] = _mergeFragments(result.last, leftPart);
      } else {
        result.add(leftPart);
      }
    }

    if (middlePart != null) {
      if (result.isNotEmpty && result.last.shouldMerge(middlePart)) {
        result[result.length - 1] = _mergeFragments(result.last, middlePart);
      } else {
        result.add(middlePart);
      }
    }

    if (rightPart != null) {
      if (result.isNotEmpty && result.last.shouldMerge(rightPart)) {
        result[result.length - 1] = _mergeFragments(result.last, rightPart);
      } else {
        result.add(rightPart);
      }
    }
  }

  void _tryMergeWithPrevious(List<TextFragment> fragments, int index) {
    if (index <= 0) return;

    final TextFragment current = fragments[index];
    final TextFragment previous = fragments[index - 1];

    if (previous.shouldMerge(current)) {
      fragments[index - 1] = _mergeFragments(previous, current);
      fragments.removeAt(index);
    }
  }

  TextFragment _mergeFragments(TextFragment a, TextFragment b) {
    return TextFragment(
      data: '${a.data}${b.data}',
      attributes: a.attributes,
    );
  }
}

extension on TextFragment {
  bool shouldMerge(TextFragment other) {
    return data is String &&
        other.data is String &&
        _equality.equals(attributes, other.attributes);
  }
}

const MapEquality<String, dynamic> _equality = MapEquality<String, dynamic>();
