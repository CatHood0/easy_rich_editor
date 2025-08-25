import '../../../../../../attributes.dart';

class ListAttribute extends EasyExclusiveBlockAttribute<String?> {
  const ListAttribute([String? value]) : super(value: value);

  const ListAttribute.ordered() : super(value: 'ordered');
  const ListAttribute.unordered() : super(value: 'unordered');
  const ListAttribute.todo() : super(value: 'todo');

  bool get isOrdered => value == 'ordered';
  bool get isUnordered => value == 'unordered';
  bool get isTodo => value == 'todo';

  @override
  ListAttribute clone(String? value) {
    return ListAttribute(value);
  }

  @override
  String get key => 'list';
}
