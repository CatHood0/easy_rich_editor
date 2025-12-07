part of '../core/easy_text.dart';

/// A specialized linked list implementation for managing [EasyText] elements
/// with optimized text manipulation and caching capabilities.
///
/// ## Usage Example:
/// ```dart
/// final textList = EasyTextList();
/// textList.add(EasyText('Hello'));
/// textList.add(EasyText(' World'));
/// print(textList.text); // Output: 'Hello World'
/// ```
final class EasyTextList extends LinkedList<EasyText> {
  /// Gets the last accessed [EasyText] element, if any.
  ///
  /// This can be useful for debugging or for operations that need to continue
  /// from the last accessed position.
  EasyText? lastUsed;

  /// Gets the index of the last accessed element, if any.
  ///
  /// Returns `null` if no element has been accessed yet or if the cache
  /// has been invalidated.
  int? lastIndex;

  EasyTextList();

  EasyTextList.from(Iterable<EasyText> iterable) {
    addAll(iterable);
  }

  /// Create a list with a single [EasyText]
  EasyTextList.easy(EasyText text) {
    add(text);
  }

  /// Create a list with a single [EasyText]
  /// containing the [text] and [styles] passed
  EasyTextList.fromStr(
    String text, [
    EasyAttributeStyles? styles,
  ]) {
    add(EasyText.fromStr(
      text: text,
      styles: styles,
    ));
  }

  /// Get a sublist of texts starting from [start] index 
  /// with the given [length].
  EasyTextList query(int start, int length) {
    final EasyTextList result = EasyTextList();
    int offset = 0;
    int remain = length;
    for (final EasyText text in this) {
      if (offset + text.length <= start) {
        offset += text.length;
        continue;
      }
      if (remain <= 0) break;
      final int localStart = math.max(0, start - offset);
      final int localEnd = math.min(
        text.length,
        localStart + remain,
      );
      if (localEnd > localStart) {
        result.add(
          text.copyWith(
            text: text.text.getRange(
              localStart,
              localEnd,
            ),
          ),
        );
        remain -= (localEnd - localStart);
      }
      offset += text.length;
    }
    return result;
  }

  /// Adds an [EasyText] entry to the end of the list and updates the text cache.
  ///
  /// If the entry already belongs to another list, it is first unlinked from
  /// that list. The text cache is updated to include the new entry's text.
  ///
  /// Throws an error if the entry is already in this list.
  @override
  void add(EasyText entry) {
    if (entry.list != null) entry.unlink();
    super.add(entry);
  }

  /// Returns the [EasyText] element at the specified [index] with optimization
  /// for consecutive access to the same index.
  ///
  /// This implementation includes a caching mechanism that remembers the last
  /// accessed element and index. If the same index is requested again and the
  /// cached element is still valid and in this list, it returns the cached
  /// element directly, avoiding list iteration.
  ///
  /// ## Performance Note:
  /// For large lists, this optimization can significantly improve access times
  /// when accessing the same position repeatedly.
  ///
  /// Throws a [RangeError] if [index] is out of bounds.
  @override
  EasyText elementAt(int index) {
    // Make a direct jump to the text to avoid iterating
    if (index == lastIndex) {
      if (lastUsed != null &&
          lastUsed!.list != null &&
          lastUsed!.list == this) {
        return lastUsed!;
      }
    }
    final EasyText text = super.elementAt(index);
    lastUsed = text;
    lastIndex = index;
    return text;
  }

  /// Generates a plain text string by concatenating the text of all [EasyText]
  /// elements in the list.
  ///
  /// This method is called lazily when the [text] getter is accessed and
  /// the cache is null.
  ///
  /// Returns an empty string if the list contains no elements.
  String toPlainText() {
    if (isEmpty) return '';
    return map<String>(
      (EasyText n) => '${n.text}',
    ).join();
  }
}
