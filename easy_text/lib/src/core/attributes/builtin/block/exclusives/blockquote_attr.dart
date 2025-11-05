import '../../../../../../attributes.dart';

class BlockquoteAttribute extends EasyExclusiveBlockAttribute<bool?> {
  const BlockquoteAttribute([bool? value]) : super(value: value);

  @override
  BlockquoteAttribute clone(bool? value) {
    return BlockquoteAttribute(value);
  }

  @override
  String get key => 'blockquote';
}
