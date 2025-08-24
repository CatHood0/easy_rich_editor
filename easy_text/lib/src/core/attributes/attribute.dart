// ignore_for_file: always_specify_types
import 'package:collection/collection.dart';
import 'package:easy_text/src/core/attributes/builtin/block/header_attr.dart';
import 'package:easy_text/src/core/attributes/builtin/inline/bold_attr.dart';
import 'package:easy_text/src/core/attributes/builtin/inline/italic_attr.dart';
import 'package:easy_text/src/core/attributes/builtin/inline/underline_attr.dart';

import 'builtin/inline/strike_attr.dart';

part 'abstractions.dart';

abstract class EasyAttribute<T extends Object?> {
  final T value;

  const EasyAttribute({required this.value});

  /// An unique key for this [EasyAttribute]
  String get key;

  /// Determines if this [EasyAttribute] will be applied
  /// to the parent of the text (whole paragraph/embed/table)
  /// or directly into the selection range
  bool get isInline;

  /// Determines if this attribute can be combined with
  /// other attributes
  ///
  /// When this is [true], if other exclusive [EasyAttribute]
  /// is setted, then this will be automatically removed
  /// since cannot be two exclsuvive [EasyAttribute]s
  bool get exclusive;

  static final Map<String, EasyAttribute> _customAttributes =
      <String, EasyAttribute<Object?>>{};

  static final Map<String, EasyAttribute> _registry =
      UnmodifiableMapView<String, EasyAttribute>(
    <String, EasyAttribute<Object?>>{
      italic.key: italic,
      bold.key: bold,
      underline.key: underline,
      strike.key: strike,
      header.key: HeaderAttribute(),
    },
  );

  static EasyAttribute? fromKeyValue(String key, dynamic value) {
    final EasyAttribute<Object?>? origin =
        _registry[key] ?? _customAttributes[key];
    if (origin == null) return null;
    final EasyAttribute<Object?> attribute = origin.clone(value);
    return attribute;
  }

  // inlines
  static const ItalicAttribute italic = ItalicAttribute();
  static const BoldAttribute bold = BoldAttribute();
  static const UnderlineAttribute underline = UnderlineAttribute();
  static const StrikeAttribute strike = StrikeAttribute();

  // blocks

  // headers and levels
  static const HeaderAttribute header = HeaderAttribute();
  static const HeaderAttribute h1 = HeaderAttribute.h1();
  static const HeaderAttribute h2 = HeaderAttribute.h2();
  static const HeaderAttribute h3 = HeaderAttribute.h3();
  static const HeaderAttribute h4 = HeaderAttribute.h4();
  static const HeaderAttribute h5 = HeaderAttribute.h5();
  static const HeaderAttribute h6 = HeaderAttribute.h6();

  EasyAttribute clone(dynamic value);
}
