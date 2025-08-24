// ignore_for_file: always_specify_types
import 'package:collection/collection.dart';
import 'package:easy_text/src/core/attributes/attribute.dart';

class EasyAttributeStyles {
  final Map<String, EasyAttribute> attributes;

  const EasyAttributeStyles({required this.attributes});
  EasyAttributeStyles.empty() : attributes = <String, EasyAttribute<Object?>>{};

  EasyAttributeStyles copy() => EasyAttributeStyles(
        attributes: <String, EasyAttribute<Object?>>{
          ...attributes,
        },
      );

  void merge(EasyAttribute attribute) {
    if (attribute.value == null) {
      attributes.remove(attribute.key);
    } else {
      attributes[attribute.key] = attribute;
    }
  }

  void mergeAll(EasyAttributeStyles other) {
    for (final EasyAttribute<Object?> attribute in other.attributes.values) {
      merge(attribute);
    }
  }

  Map<String, dynamic> mergeJson([Map<String, dynamic>? left]) {
    final Map<String, dynamic> map = <String, dynamic>{...?left};
    for (MapEntry<String, EasyAttribute<dynamic>> el in attributes.entries) {
      if (el.value.value == null || el.value.value == false) {
        map.remove(el.key);
      } else {
        map[el.key] = el.value;
      }
    }

    return map;
  }

  static EasyAttributeStyles fromJson(
    Map<String, dynamic>? attributes, {
    EasyAttribute? Function(String, dynamic)? onUnknownAttribute,
  }) {
    if (attributes == null) {
      return EasyAttributeStyles.empty();
    }

    final Map<String, EasyAttribute> result =
        attributes.map<String, EasyAttribute>((
      String key,
      dynamic value,
    ) {
      final EasyAttribute<Object?>? attr =
          EasyAttribute.fromKeyValue(key, value) ??
              onUnknownAttribute?.call(key, value);
      assert(
          attr != null,
          'attribute must be '
          'registered in EasyAttribute using '
          'EasyAttribute.custom or onUnknownAttribute from configs');
      return MapEntry<String, EasyAttribute>(
        key,
        attr!,
      );
    });
    return EasyAttributeStyles(attributes: result);
  }

  Map<String, dynamic>? toJson() => attributes.isEmpty
      ? null
      : attributes.map<String, dynamic>((_, EasyAttribute<Object?> attribute) =>
          MapEntry<String, dynamic>(attribute.key, attribute.value));

  Iterable<String> get keys => attributes.keys;

  bool get isEmpty => attributes.isEmpty;

  bool get isNotEmpty => attributes.isNotEmpty;

  EasyAttribute get single => attributes.values.single;

  bool containsKey(String key) => attributes.containsKey(key);

  EasyAttributeStyles put(EasyAttribute attribute) {
    final Map<String, EasyAttribute> m =
        Map<String, EasyAttribute>.from(attributes);
    m[attribute.key] = attribute;
    return EasyAttributeStyles(attributes: m);
  }

  @override
  bool operator ==(covariant EasyAttributeStyles other) {
    if (identical(this, other)) return true;
    return _eq.equals(attributes, other.attributes);
  }

  @override
  int get hashCode {
    final Iterable<int> hashes = attributes.entries.map(
      (MapEntry<String, EasyAttribute<Object?>> entry) => Object.hash(
        entry.key,
        entry.value,
      ),
    );
    return Object.hashAll(hashes);
  }

  @override
  String toString() => "{${attributes.values.join(', ')}}";
}

const MapEquality<String, EasyAttribute<Object?>> _eq =
    MapEquality<String, EasyAttribute>();
