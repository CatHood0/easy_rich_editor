import 'package:flutter/widgets.dart';
import '../../../../../../attributes.dart';

class TextDirectionAttribute extends EasyBlockAttribute<String?> {
  const TextDirectionAttribute([String? value]) : super(value: value);

  const TextDirectionAttribute.ltr() : super(value: 'ltr');
  const TextDirectionAttribute.rtl() : super(value: 'rtl');

  TextDirection get directionality {
    if (value == 'ltr') return TextDirection.ltr;
    if (value == 'rtl') return TextDirection.rtl;
    return TextDirection.ltr;
  }

  @override
  TextDirectionAttribute clone(String? value) {
    return TextDirectionAttribute(value);
  }

  @override
  String get key => 'text-direction';
}
