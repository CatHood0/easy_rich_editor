import 'package:easy_rich_editor/src/core/api/attributes/attribute.dart';

extension EasyAttributeList<T> on List<EasyAttribute<T>> {
  Map<String, dynamic> toJson([Map<String, dynamic>? left]) {
    final Map<String, dynamic> map = <String, dynamic>{...?left};
    for (EasyAttribute<dynamic> el in this) {
      map[el.key] = el.value;
      if (el.value == null || el.value == false) {
        map.remove(el.key);
      }
    }
    return map;
  }
}

extension EasyMapAttributes on Map<String, dynamic> {
  Map<String, dynamic>? nullIfEmpty() => isEmpty ? null : this;
}
