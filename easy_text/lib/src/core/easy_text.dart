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
final class EasyText extends LinkedListEntry<EasyText> {
  /// Unique identifier for this text fragment
  final String id;

  /// The styling attributes applied to this text fragment
  final EasyAttributeStyles styles;

  Characters _text;

  /// The character content of this text fragment
  ///
  /// We use [Characters] from `character` package
  /// to maintain a better stability when making
  /// inserting, moving or deleting operatinons
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

  /// Determines if this element is the first one into the list
  bool get isFirst => list == null ? false : list!.first == this;

  /// Determines if this element is the last one into the list
  bool get isLast => list == null ? false : list!.last == this;

  /// try to merge this element with adjacents parts if they share
  /// the same style.
  void tryMerge() {
    // This is a text node and it can only be merged with other text nodes.
    EasyText textPart = this;
    final bool isThisLastUsed = (list as EasyTextList?)?._lastUsedText == this;

    // Merging it with previous textPart if style is the same.
    final EasyText? prev = textPart.previous;
    if (!textPart.isFirst && prev != null && prev.styles == textPart.styles) {
      int? prevLength = prev._length != null ? prev.length : null;
      int? nodeLength = textPart._length != null ? textPart.length : null;
      prev.text = prev.text + textPart.text;
      if (prevLength != null) {
        nodeLength ??= textPart.length;
        textPart._length = prevLength + nodeLength;
      }
      // moved the focus to this since at some points, we
      // want to move to the wanted fragment without
      // searching it first manually
      if (isThisLastUsed) {
        (list as EasyTextList?)?._lastUsedText = prev;
      }
      textPart.unlink();
      textPart = prev;
    }

    // Merging it with next node if style is the same.
    final EasyText? next = textPart.next;
    if (!textPart.isLast && next != null && next.styles == textPart.styles) {
      int? nextLength = next._length != null ? next.length : null;
      int? nodeLength = textPart._length != null ? textPart.length : null;
      textPart.text = textPart.text + next.text;
      // computes the new length to avoid unnecessary calculations
      if (nextLength != null) {
        nodeLength ??= textPart.length;
        next._length = nextLength + nodeLength;
      }
      next.unlink();
    }
  }

  /// Inserts text at the specified [index] with optional styling.
  ///
  /// ## Throws:
  /// - [AssertionError] if [index] is out of bounds (negative or greater than length).
  ///
  /// ## Example:
  /// ```dart
  /// final text = EasyText('Hello World');
  /// text.insert(6, 'Beautiful '); // Result: 'Hello Beautiful World'
  /// text.insert(6, 'Amazing ', style: EasyAttributeStyles(attributes: {'bold': BoldAttribute()}));
  /// ```
  void insert(
    int index,
    String data, [
    EasyAttributeStyles? style,
    bool ignoreMerge = false,
  ]) {
    final int length = this.length;
    assert(
        index >= 0 && index <= length, 'Index must be between 0 and $length');
    final EasyText part = EasyText.fromStr(text: data);
    (list as EasyTextList?)?.insertText(data, index);
    if (index < length) {
      splitAt(index)!.insertBefore(part);
    } else {
      insertAfter(part);
    }
    part.format(
      style,
      true,
      ignoreMerge,
    );
  }

  /// Applies formatting to a range of text starting at [index] for [len] characters.
  ///
  /// ## Example:
  /// ```dart
  /// final text = EasyText('Hello World');
  /// text.formatRange(6, 5, EasyAttributeStyles([BoldAttribute()]));
  /// // Formats 'World' as bold
  /// ```
  void formatRange(
    int index,
    int? len,
    EasyAttributeStyles? style, {
    bool overrideStylesIfEmpty = true,
  }) {
    if (style == null || len == null || len <= 0) return;

    final int local = math.min<int>(length - index, len);
    final int remain = len - local;
    final EasyText part = _splitExactRanges(index, local);
    (list as EasyTextList?)
      ?.._lastUsedText = part
      .._lastIndex = null;

    if (remain > 0 && part.next != null) {
      part.next?.formatRange(
        0,
        remain,
        style,
        overrideStylesIfEmpty: overrideStylesIfEmpty,
      );
    }
    part.format(
      style,
      overrideStylesIfEmpty,
    );
  }

  /// Deletes [len] characters starting from the specified [index].
  ///
  /// ## Throws:
  /// - [AssertionError] if [index] is out of bounds (>= length).
  ///
  /// ## Example:
  /// ```dart
  /// final text = EasyText('Hello Beautiful World');
  /// text.delete(6, 10); // Result: 'Hello World'
  /// text.delete(0, 5);  // Result: 'World'
  /// ```
  void delete(
    int index,
    int len, {
    bool ignoreMerge = false,
  }) {
    final int length = this.length;
    assert(index < length, 'offset must be less than the length passed');

    final int local = math.min(length - index, len);
    final EasyText target = _splitExactRanges(index, local);
    final EasyText? prev = target.previous;
    final EasyText? next = target.next;
    // Since getting offset of the current target can have too much
    // cost, we prefer just invalidating the cached text
    invalidateParentCache();
    target.unlink();

    final int remain = len - local;
    if (remain > 0 && next != null) {
      next.delete(0, remain);
    }

    if (prev != null && !ignoreMerge) prev.tryMerge();
  }

  /// Split efficiently starting at [index] with specified [length].
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
  void format(
    EasyAttributeStyles? style, [
    bool overrideStylesIfEmpty = false,
    bool ignoreMerge = false,
  ]) {
    if (style != null) {
      overrideStylesIfEmpty && style.isEmpty
          ? styles.clearAll()
          : applyStyle(style);
    }
    if (!ignoreMerge) tryMerge();
  }

  /// Splits this [EasyText] at specified [offset]
  ///
  /// Returns the inserted [EasyText] object
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
  void invalidateParentCache() {
    if (list == null || (list as EasyTextList)._text == null) return;
    (list as EasyTextList).text = null;
  }

  /// Inserts the given entry after this entry in the linked list.
  ///
  /// If the entry is already in a list, it will be unlinked first.
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

  /// Whether this element is equals than the other [EasyText]
  /// comparing its [text] and [styles]
  bool deepEquals(EasyText other) =>
      text == other.text && styles == other.styles || this == other;

  @override
  int get hashCode => Object.hashAllUnordered(<Object?>[id]);

  @override
  bool operator ==(covariant EasyText other) {
    if (identical(this, other)) return true;
    return id == other.id;
  }
}
