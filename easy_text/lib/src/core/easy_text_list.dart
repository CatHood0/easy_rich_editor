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
  /// Cached reference to the last accessed [EasyText] element for optimized
  /// subsequent access. This reduces iteration overhead when accessing the
  /// same element multiple times.
  EasyText? _lastUsedText;

  /// The index position of the last accessed element. Used in conjunction with
  /// [_lastUsedText] to provide direct jump access to recently used elements.
  int? _lastIndex;

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
    if (index == _lastIndex) {
      if (_lastUsedText != null &&
          _lastUsedText!.list != null &&
          _lastUsedText!.list == this) {
        return _lastUsedText!;
      }
    }
    final EasyText text = super.elementAt(index);
    _lastUsedText = text;
    _lastIndex = index;
    return text;
  }

  /// Gets the last accessed [EasyText] element, if any.
  ///
  /// This can be useful for debugging or for operations that need to continue
  /// from the last accessed position.
  EasyText? get lastUsed => _lastUsedText;

  /// Gets the index of the last accessed element, if any.
  ///
  /// Returns `null` if no element has been accessed yet or if the cache
  /// has been invalidated.
  int? get lastIndex => _lastIndex;

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
