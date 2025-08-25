import 'dart:collection';
import 'dart:math' as math;

import 'package:characters/characters.dart';
import 'package:easy_text/src/core/attributes/attribute.dart';
import 'package:easy_text/src/core/easy_attribute_styles.dart';
import 'package:uuid/v4.dart';

part '../core/easy_text_list.dart';

const UuidV4 uuid = UuidV4();

/// Represents a contiguous segment of text with
/// consistent styling attributes.
///
/// Multiple [EasyText] instances can be
/// linked together to form a complete styled text document.
final class EasyText extends LinkedListEntry<EasyText> {
  /// Unique identifier for this text fragment
  final String id;

  /// The styling attributes applied to this text fragment
  final EasyAttributeStyles styles;

  /// The character content of this text fragment
  ///
  /// We use [Characters] from `character` package
  /// to maintain a better stability when making
  /// inserting, moving or deleting operatinons
  Characters _text;

  Characters get text => _text;

  set text(Characters text) {
    _text = text;
    _length = null;
  }

  int? _length;

  /// Creates an [EasyText] instance with the specified text and styles.
  EasyText({
    required Characters text,
    EasyAttributeStyles? styles,
  })  : _text = text,
        id = uuid.generate(),
        styles = styles ?? EasyAttributeStyles.empty();

  /// Creates an [EasyText] instance from a regular string with specified styles.
  EasyText.fromStr({
    required String text,
    EasyAttributeStyles? styles,
  })  : id = uuid.generate(),
        _text = text.characters,
        styles = styles ?? EasyAttributeStyles.empty();

  /// Creates an empty [EasyText] instance with no content and empty styles.
  ///
  /// Useful as a placeholder or for initialization purposes.
  EasyText.empty()
      : styles = EasyAttributeStyles(
          attributes: <String, EasyAttribute<dynamic>>{},
        ),
        id = uuid.generate(),
        _text = Characters.empty;

  /// Returns a substring containing characters before the specified point.
  Characters? before(int point) {
    return text.getRange(0, point);
  }

  /// Returns a substring between the specified start and end positions.
  Characters? between(int start, int end) {
    return text.getRange(start, end);
  }

  /// Returns a substring containing characters after the specified point.
  Characters? after(int point) {
    return text.getRange(point);
  }

  /// The length of this text fragment in characters.
  ///
  /// This value is cached after first calculation for performance.
  int get length => _length ??= text.length;

  /// Indicates whether this text fragment contains any character content.
  bool get hasText => text.isNotEmpty;

  /// Determines if this [EasyText] instance is currently linked to a parent list.
  bool get isLinked => list != null;

  bool get isFirst => list == null ? false : list!.first == this;
  bool get isLast => list == null ? false : list!.last == this;

  /// tryMergeAdjacentText this text by merging it with adjacent [EasyText] parts if they share
  /// the same style.
  void tryMergeAdjacentText() {
    // This is a text node and it can only be merged with other text nodes.
    EasyText node = this;
    final bool isThisLastUsed = (list as EasyTextList?)?._lastUsedText == this;

    // Merging it with previous node if style is the same.
    final EasyText? prev = node.previous;
    if (!node.isFirst && prev != null && prev.styles == node.styles) {
      int? prevLength = prev._length != null ? prev.length : null;
      int? nodeLength = node._length != null ? node.length : null;
      prev.text = prev.text + node.text;
      if (prevLength != null) {
        nodeLength ??= node.length;
        node._length = prevLength + nodeLength;
      }
      // moved the focus to this since at some points, we 
      // want to move to the wanted fragment without
      // searching it first manually
      if (isThisLastUsed) {
        (list as EasyTextList?)?._lastUsedText = prev;
      }
      node.unlink();
      node = prev;
    }

    // Merging it with next node if style is the same.
    final EasyText? next = node.next;
    if (!node.isLast && next != null && next.styles == node.styles) {
      int? nextLength = next._length != null ? next.length : null;
      int? nodeLength = node._length != null ? node.length : null;
      node.text = node.text + next.text;
      // computes the new length to avoid unnecessary calculations
      if (nextLength != null) {
        nodeLength ??= node.length;
        next._length = nextLength + nodeLength;
      }
      next.unlink();
    }
  }

  void insert(
    int index,
    String data, [
    EasyAttributeStyles? style,
  ]) {
    final int length = this.length;
    assert(index >= 0 && index <= length, '');
    final EasyText node = EasyText.fromStr(text: data);
    (list as EasyTextList?)?.insertText(data, index);
    if (index < length) {
      splitAt(index)!.insertBefore(node);
    } else {
      insertAfter(node);
    }
    node.format(style);
  }

  void formatRange(
    int index,
    int? len,
    EasyAttributeStyles? style,
  ) {
    if (style == null) return;

    final int local = math.min<int>(length - index, len!);
    final int remain = len - local;
    final EasyText node = _splitExactRanges(index, local);
    (list as EasyTextList?)
      ?.._lastUsedText = node
      .._lastIndex = null;

    if (remain > 0 && node.next != null) {
      node.next?.formatRange(0, remain, style);
    }
    node.format(style);
  }

  //FIXME: probably we can find a way to avoid invalidating the cache
  void delete(
    int index,
    int? len,
  ) {
    final int length = this.length;
    assert(index < length, 'offset must be less than the length passed');

    final int local = math.min(length - index, len!);
    final EasyText target = _splitExactRanges(index, local);
    final EasyText? prev = target.previous;
    final EasyText? next = target.next;
    // since getting offset of the current target can have too much
    // cost, we prefer just invalidating the cached text
    invalidaParentCache();
    target.unlink();

    final int remain = len - local;
    if (remain > 0 && next != null) {
      next.delete(0, remain);
    }

    if (prev != null) {
      prev.tryMergeAdjacentText();
    }
  }

  /// Isolates a new [EasyText] starting at [index] with specified [length].
  EasyText _splitExactRanges(int index, int length) {
    assert(
      index >= 0 && index < this.length && (index + length <= this.length),
      'the index($index) or '
      'length($length) are not into the '
      'defined range of: 0 to ${this.length}',
    );
    final EasyText target = splitAt(index)!..splitAt(length);
    return target;
  }

  /// Formats this [EasyText] and optimizes it with adjacent [EasyText]s if needed.
  void format(EasyAttributeStyles? style) {
    if (style != null && style.isNotEmpty) {
      applyStyle(style);
    }
    tryMergeAdjacentText();
  }

  /// Splits this [EasyText] at specified [offset]
  ///
  /// Returns the inserted [EasyText] object
  ///
  /// In case a new node is actually split from this one, it inherits this
  /// node's style.
  EasyText? splitAt(int index) {
    assert(
        index >= 0 && index <= length,
        'offset $index does '
        'not satisfy the range '
        'of this text => 0 to $length');
    if (index == 0) return this;
    if (index == length) return isLast ? null : next;

    final EasyText split = EasyText(
      text: after(index)!,
      styles: styles.copy(),
    );
    text = before(index)!;
    insertAfter(split);
    return split;
  }

  /// Apply all the styles passed to the current [EasyText]
  void applyStyle(EasyAttributeStyles value) {
    styles.mergeAll(value);
  }

  /// Gets the starting offset of this fragment within its parent list.
  int get offset {
    if (list == null) return -1;
    int offset = 0;
    for (EasyText el in list!) {
      if (el == this) break;
      offset += el.length;
    }
    return offset;
  }

  /// Gets the ending offset of this fragment within its parent list.
  ///
  /// This represents the position immediately after the last character
  /// of this fragment in the complete text.
  int get endOffset => list == null ? -1 : offset + length;

  /// Invalidates the cached text representation of the parent list.
  ///
  /// Should be called when this fragment's content changes to ensure
  /// the parent list recalculates its cached text representation.
  void invalidaParentCache() {
    if (list == null) return;
    (list as EasyTextList).text = null;
  }

  /// Inserts the given entry after this entry in the linked list.
  ///
  /// If the entry is already in a list, it will be unlinked first.
  ///
  /// @param entry The entry to insert after this one
  @override
  void insertAfter(EasyText entry) {
    if (entry.list != null) entry.unlink();
    super.insertAfter(entry);
  }

  /// Inserts the given entry before this entry in the linked list.
  ///
  /// If the entry is already in a list, it will be unlinked first.
  @override
  void insertBefore(EasyText entry) {
    if (entry.list != null) entry.unlink();
    super.insertBefore(entry);
  }

  /// Creates a copy of this [EasyText] instance with optional modifications.
  EasyText copyWith({
    Characters? text,
    EasyAttributeStyles? styles,
  }) {
    return EasyText(
      text: text ?? this.text,
      styles: styles ?? this.styles,
    );
  }

  @override
  String toString() {
    return 'EasyText(text: $text, styles: ${styles.toJson()})';
  }

  @override
  int get hashCode => Object.hashAllUnordered(<Object?>[id]);

  @override
  bool operator ==(covariant EasyText other) => id == other.id;
}
