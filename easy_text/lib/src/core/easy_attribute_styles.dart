import 'package:collection/collection.dart';
import '../../attributes.dart';

const MapEquality<String, EasyAttribute<Object?>> _eq =
    MapEquality<String, EasyAttribute>();

class EasyAttributeStyles {
  final Map<String, EasyAttribute> attributes;

  const EasyAttributeStyles({required this.attributes});

  EasyAttributeStyles.empty() : attributes = <String, EasyAttribute<Object?>>{};

  EasyAttributeStyles.fromAttribute(EasyAttribute attr)
      : attributes = <String, EasyAttribute<Object?>>{attr.key: attr};

  EasyAttributeStyles.fromIterable(Iterable<EasyAttribute> attr)
      : attributes = <String, EasyAttribute<Object?>>{}..addEntries(
            attr.map<MapEntry<String, EasyAttribute>>(
              (EasyAttribute<Object?> e) {
                return MapEntry<String, EasyAttribute>(e.key, e);
              },
            ),
          );

  /// Whether there are available styles
  bool get isEmpty => attributes.isEmpty;

  /// Whether there no styles available
  bool get isNotEmpty => attributes.isNotEmpty;

  /// The keys of this [EasyAttributeStyles]
  Iterable<String> get keys => attributes.keys;

  /// The values of this [EasyAttributeStyles]
  Iterable<EasyAttribute> get values => attributes.values;

  /// The number of attributes available
  int get length => attributes.length;

  EasyAttribute get single => attributes.values.single;

  /// Clear all the styles in this container
  EasyAttributeStyles clearAll() {
    final EasyAttributeStyles copy = this.copy();
    attributes.clear();
    return copy;
  }

  /// Whether these styles contain the [key] passed
  bool containsKey(String key) => attributes.containsKey(key);

  /// Whether these styles contain the [value] passed
  bool containsValue(EasyAttribute value) => attributes.containsValue(value);

  /// Returns a copy of these styles into a new container instance
  EasyAttributeStyles copy() => EasyAttributeStyles(
        attributes: <String, EasyAttribute<Object?>>{
          ...attributes,
        },
      );

  /// Returns the attribute that match with the type assigned
  EasyAttribute? getByType<T extends EasyAttribute>({
    bool Function(EasyAttribute)? filter,
  }) {
    bool easyFilter(EasyAttribute attr) => true;
    filter ??= easyFilter;
    return attributes.values.firstWhereOrNull(
      (EasyAttribute<Object?> a) => a is T && filter!(a),
    );
  }

  /// Merge the [attribute] into these style container
  /// and removes it if the value is [null] or [false]
  void merge(EasyAttribute attribute, {bool autoRemoveExclusives = true}) {
    if (autoRemoveExclusives &&
        attribute.exclusive &&
        attribute.value != null) {
      bool hasExclusive = true;
      // search first the knowed exclusive attributes
      for (final EasyAttribute<Object?> exclusive
          in EasyAttribute.exclusives.values) {
        if (attributes.containsKey(exclusive.key)) {
          attributes.remove(exclusive.key);
          hasExclusive = false;
          break;
        }
      }

      if (hasExclusive) {
        for (String key in attributes.keys) {
          final EasyAttribute<Object?>? value = attributes[key];
          assert(value != null,
              'value must be non null since is registered in ${toJson()}');
          if (value!.exclusive) {
            attributes.remove(key);
            break;
          }
        }
      }
    }
    attribute.value == null
        ? attributes.remove(attribute.key)
        : attributes[attribute.key] = attribute;
  }

  /// Merge the all the styles into these style container
  /// passed and removes it if the value is [null] or [false]
  void mergeAll(EasyAttributeStyles styles) {
    for (final EasyAttribute<Object?> attribute in styles.values) {
      merge(attribute);
    }
  }

  /// Returns a new style container with the new attribute
  EasyAttributeStyles put(EasyAttribute attribute) {
    final Map<String, EasyAttribute> m =
        Map<String, EasyAttribute>.from(attributes);
    m[attribute.key] = attribute;
    return EasyAttributeStyles(attributes: m);
  }

  Map<String, dynamic>? toJson() => attributes.isEmpty
      ? null
      : attributes.map<String, dynamic>((_, EasyAttribute<Object?> attribute) =>
          MapEntry<String, dynamic>(attribute.key, attribute.value));

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
      final EasyAttribute<Object?> attr =
          EasyAttribute.fromKeyValue(key, value) ??
              onUnknownAttribute?.call(key, value) ??
              EasyAttribute.alternativeNames[key]?.clone(value) ??
              EasyAttribute.alternativeNames[value] ??
              UnknownAttribute(
                value: value,
                key: key,
              );
      return MapEntry<String, EasyAttribute>(
        key,
        attr,
      );
    });
    return EasyAttributeStyles(attributes: result);
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
