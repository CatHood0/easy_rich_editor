import '../../../../../attributes.dart';

class BlockIndentAttribute extends EasyBlockAttribute<int?> {
  const BlockIndentAttribute([int? level]) : super(value: level);

  const BlockIndentAttribute.one() : super(value: 1);
  const BlockIndentAttribute.two() : super(value: 2);
  const BlockIndentAttribute.three() : super(value: 3);
  const BlockIndentAttribute.four() : super(value: 4);
  const BlockIndentAttribute.five() : super(value: 5);
  const BlockIndentAttribute.six() : super(value: 6);
  const BlockIndentAttribute.seven() : super(value: 7);

  @override
  BlockIndentAttribute clone(int? value) {
    return BlockIndentAttribute(value);
  }

  @override
  String get key => 'block-indent';
}
