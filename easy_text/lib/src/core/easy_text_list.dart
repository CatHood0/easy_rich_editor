part of '../core/easy_text.dart';

final class EasyTextList extends LinkedList<EasyText> {
  EasyText? _lastUsedText;
  int? _lastIndex;
  String? _text;

  String get text => _text ??= toPlainText();

  set text(String? text) {
    _text = text;
  }

  @override
  void add(EasyText entry) {
    if (entry.list != null) entry.unlink();
    if (_text != null) text = '$text${entry.text}';
    super.add(entry);
  }

  @override
  EasyText elementAt(int index) {
    // make a direct jump to the text
    // to avoid iterating
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

  EasyText? get lastUsed => _lastUsedText;
  int? get lastIndex => _lastIndex;

  String toPlainText() {
    if (isEmpty) return '';
    return map<String>(
      (EasyText n) => '${n.text}',
    ).join();
  }

  void insertText(String text, [int position = 0]) {
    if (_text == null) return;

    text = text.replaceRange(position, position, text);
  }

  void removeText(int position, int len) {
    if (_text == null || len <= 0) return;

    text = text.replaceRange(position, len, text);
  }
}
