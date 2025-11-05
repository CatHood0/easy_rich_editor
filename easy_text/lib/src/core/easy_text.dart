import 'dart:collection';
import 'dart:math' as math;
import 'dart:math';

import 'package:characters/characters.dart';
import 'package:uuid/v4.dart';
import '../../easy_text.dart';
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
    String? id,
    required Characters text,
    EasyAttributeStyles? styles,
  })  : _text = text,
        id = id ?? uuid.generate(),
        styles = styles ?? EasyAttributeStyles.empty();

  /// Creates an [EasyText] instance from a regular string with specified styles.
  EasyText.fromStr({
    String? id,
    required String text,
    EasyAttributeStyles? styles,
  })  : id = id ?? uuid.generate(),
        _text = text.characters,
        styles = styles ?? EasyAttributeStyles.empty();

  /// Creates an empty [EasyText] instance with no content and empty styles.
  ///
  /// Useful as a placeholder or for initialization purposes.
  EasyText.empty({String? id})
      : styles = EasyAttributeStyles(
          attributes: <String, EasyAttribute<dynamic>>{},
        ),
        id = id ?? uuid.generate(),
        _text = Characters.empty;

  /// Returns a substring containing characters before the specified point.
  Characters before(int point) {
    return text.getRange(0, point);
  }

  /// Returns a substring between the specified start and end positions.
  Characters between(int start, int end) {
    return text.getRange(start, end);
  }

  /// Returns a substring containing characters after the specified point.
  Characters after(int point) {
    return text.getRange(point);
  }

  /// Splits this sequence of characters at each occurrence of [pattern].
  ///
  /// Returns a lazy iterable of characters that were separated by [pattern].
  /// The iterable has *at most* [maxParts] elements if a positive [maxParts]
  /// is supplied.
  Iterable<Characters> split(Characters pattern) {
    return text.split(pattern);
  }

  /// Returns the single-character sequence of the [position]th character.
  ///
  /// The [position] must be non-negative and less than [length].
  Characters charAt(int at) {
    return text.characterAt(at);
  }

  /// The characters of the lower-case version of [string].
  Characters toLowerCase() => text.toLowerCase();

  /// The characters of the upper-case version of [string].
  Characters toUpperCase() => text.toUpperCase();

  /// Returns the [String] associated to the [Characters] instance
  String str() => '$text';

  /// The length of this text fragment in characters.
  ///
  /// This value is cached after first calculation for performance.
  int get length => _length ??= text.length;

  /// Indicates whether this text fragment contains any character content.
  bool get hasText => text.isNotEmpty;

  /// Indicates whether this text fragment is fully empty.
  bool get isBlank => text.isEmpty;

  /// Determines if this [EasyText] instance is currently linked to a parent list.
  bool get isLinked => list != null;

  /// Determines if this element is the first one into the list
  bool get isFirst => list == null ? false : list!.first == this;

  /// Determines if this element is the last one into the list
  bool get isLast => list == null ? false : list!.last == this;

  /// Overrides the last used [EasyText] instance
  void setAsLastUsed() {
    if (!isLinked) return;
    (list as EasyTextList?)?.lastUsed = this;
  }

  /// try to merge this element with adjacents parts if they share
  /// the same style.
  void tryMerge() {
    // This is a text node and it can only be merged with other text nodes.
    EasyText textPart = this;
    final bool isThisLastUsed = (list as EasyTextList?)?.lastUsed == this;

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
        (list as EasyTextList?)?.lastUsed = prev;
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
  /// ## Example:
  /// ```dart
  /// final text = EasyText.fromStr(text: 'Hello World');
  /// text.insert(6, 'Beautiful '); // Result: 'Hello Beautiful World'
  /// text.insert(6, 'Amazing ', style: EasyAttributeStyles.fromJson({'bold': BoldAttribute()}));
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
    style ??= EasyAttributeStyles.empty();
    // if both share the same attributes, just
    // insert the data at the position
    // without splitting
    //
    // this should avoid unlinking instances
    // when not required
    if (this.styles == style && index <= length) {
      final Characters chars = data.characters;
      if (_length != null) _length = length + chars.length;
      _text = before(min(
            index,
            length,
          )) +
          chars +
          after(min(
            index,
            length,
          ));
      return;
    }

    final EasyText part = EasyText.fromStr(text: data);

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
  /// final text = EasyText.fromStr(text: 'Hello World');
  /// // Formats 'World' as bold
  /// text.formatRange(6, 5, EasyAttributeStyles.fromAttribute(BoldAttribute()));
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
    final EasyText part = extractAt(index, local);

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
  /// ## Example:
  /// ```dart
  /// final text = EasyText.fromStr(text: 'Hello Beautiful World');
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

    final int local = math.min<int>(length - index, len);
    final EasyText extracted = extractAt(index, local);
    final EasyText? prev = extracted.previous;
    final EasyText? next = extracted.next;
    // removes the selected part
    extracted.unlink();

    final int remain = len - local;
    if (remain > 0 && next != null) {
      next.delete(0, remain);
    }

    if (prev != null && !ignoreMerge) prev.tryMerge();
  }

  /// Extract efficiently starting at [index] with specified [length].
  EasyText extractAt(int index, int length) {
    assert(
      index >= 0 && index < this.length && (index + length <= this.length),
      'the index($index) or '
      'length($length) are not into the '
      'defined range of: 0 to ${this.length}',
    );
    // Extracts a substring starting from the specified index with the given length
    final EasyText left = splitAt(index)!
      // Example:
      //   Input: index = 5, length = 13
      //   Text: "This is an example text where we shows how works this"
      //
      //   Visual representation:
      //   "This |is an example| text where we shows how works this"
      //          ↑____________↑
      //          index 5, length 13
      //
      //   Returns: "is an example"
      //
      // The remaining parts of the original text are processed separately
      // in a new instance or data structure
      ..splitAt(length);
    final EasyText target = left;
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
      text: after(index),
      styles: styles.copy(),
    );
    text = before(index);
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
    String? id,
    Characters? text,
    EasyAttributeStyles? styles,
  }) {
    return EasyText(
      id: id ?? this.id,
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
  @Deprecated(
      'deepEquals will be removed in future releases. Please, use strictEquals instead')
  bool deepEquals(Object other) =>
      other is EasyText && text == other.text && styles == other.styles;

  /// Determines if an object is equals than this [EasyText] instance
  ///
  /// Useful for when you need to know if an [EasyText] and another
  /// are fully different
  ///
  /// Example:
  /// ```dart
  /// // like the key in a HashMap with requires strict equality
  /// final strictMap = HashMap<EasyText, String>(
  ///   equals: (a, b) => a.strictEquals(b),
  ///   hashCode: (obj) => obj.strictHashCode,
  /// );
  /// ```
  bool strictEquals(Object other) {
    if (identical(this, other)) return true;
    if (other is! EasyText) return false;
    return text == other.text && styles == other.styles && id == other.id;
  }

  /// The strict hash code version for this [EasyText] instance
  ///
  /// Example:
  /// ```dart
  /// // like the key in a HashMap with requires strict equality
  /// final strictMap = HashMap<EasyText, String>(
  ///   equals: (a, b) => a.strictEquals(b),
  ///   hashCode: (obj) => obj.strictHashCode,
  /// );
  /// ```
  int get strictHashCode => Object.hash(
        text,
        styles,
        id,
      );

  @override
  int get hashCode => Object.hash(
        id,
        null,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! EasyText) return false;
    return id == other.id;
  }
}
