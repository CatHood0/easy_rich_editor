import 'package:easy_text/src/core/attributes/builtin/block/direction_attr.dart';
import 'package:flutter/widgets.dart';
import '../../../../../../attributes.dart';

class AlignmentAttribute extends EasyBlockAttribute<String?> {
  const AlignmentAttribute([String? value]) : super(value: value);

  const AlignmentAttribute.left() : super(value: 'left');
  const AlignmentAttribute.right() : super(value: 'right');
  const AlignmentAttribute.center() : super(value: 'center');

  @override
  String get key => 'align';

  @override
  AlignmentAttribute clone(String? value) {
    return AlignmentAttribute(value);
  }

  // makes a manuall deletion of [TextDirectionAttribute]
  // since we cannot/must have two direction modifiers
  // in a same block
  @override
  bool canMergeWith(EasyAttribute<Object?> attribute) =>
      attribute is! TextDirectionAttribute;

  Alignment get align {
    if (value == 'right') return Alignment.centerRight;
    if (value == 'center') return Alignment.center;
    return Alignment.centerLeft;
  }
}
