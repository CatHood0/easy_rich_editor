import 'dart:collection';

import 'package:characters/characters.dart';
import 'package:easy_text/src/core/attributes/attribute.dart';
import 'package:easy_text/src/core/easy_attribute_styles.dart';
import 'package:uuid/v4.dart';

part '../core/easy_text_list.dart';

const UuidV4 uuid = UuidV4();

final class EasyText extends LinkedListEntry<EasyText> {
  final String id;
  final Characters text;
  final EasyAttributeStyles styles;

  int? _length;

  EasyText({
    required this.text,
    required this.styles,
  }) : id = uuid.generate();

  EasyText.fromStr({
    required String text,
    required this.styles,
  })  : id = uuid.generate(),
        text = text.characters;

  EasyText.empty()
      : styles = EasyAttributeStyles(
          attributes: <String, EasyAttribute<dynamic>>{},
        ),
        id = uuid.generate(),
        text = Characters.empty;

  Characters? before(int point) {
    return text.getRange(0, point);
  }

  Characters? between(int start, int end) {
    return text.getRange(start, end);
  }

  Characters? after(int point) {
    return text.getRange(point);
  }

  int get length => _length ??= text.length;

  bool get hasText => text.isNotEmpty;

  // Get the offset of this fragment into its parent list
  int get offset {
    if (list == null) return -1;
    int offset = 0;
    for (EasyText el in list!) {
      if (el == this) break;
      offset += el.length;
    }
    return offset;
  }

  int get endOffset => list == null ? -1 : offset + length;

  void invalidaParentCache() {
    if (list == null) return;
    (list as EasyTextList).text = null;
  }

  @override
  void insertAfter(EasyText entry) {
    if (entry.list != null) entry.unlink();
    super.insertAfter(entry);
  }

  @override
  void insertBefore(EasyText entry) {
    if (entry.list != null) entry.unlink();
    super.insertBefore(entry);
  }

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
  int get hashCode => Object.hashAllUnordered(<Object?>[id]);

  @override
  bool operator ==(covariant EasyText other) => id == other.id;
}
