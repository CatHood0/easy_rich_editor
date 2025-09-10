import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import '../../../../../easy_rich_editor.dart';

@internal
class FixedListLength {
  final QueueList<EasyOperation> _operations;
  late final int numberOfOperations;
  final int maxLength;
  static const int defaultMaxLength = 300;

  FixedListLength({
    required Iterable<EasyOperation> operations,
    this.maxLength = defaultMaxLength,
  })  : assert(
            operations.length <= maxLength,
            'length of the operations must be '
            'less or equals that the maxLength passed'),
        _operations = QueueList<EasyOperation>.from(operations) {
    numberOfOperations = _operations.length;
  }

  FixedListLength.empty({
    this.maxLength = defaultMaxLength,
  }) : _operations = QueueList<EasyOperation>();

  /// Removes and returns the first element of this queue.
  ///
  /// The queue must not be empty when this method is called.
  EasyOperation takeHead() {
    numberOfOperations--;
    return _operations.removeLast();
  }

  /// Removes and returns the last element of the queue.
  ///
  /// The queue must not be empty when this method is called.
  EasyOperation takeOldMember() {
    numberOfOperations--;
    return _operations.removeFirst();
  }

  /// Returns the most recent operation added
  EasyOperation? getRecent() {
    return _operations.lastOrNull;
  }

  /// Adds [value] at the beginning of the queue.
  void addFirst(EasyOperation value) {
    numberOfOperations++;
    _operations.addFirst(value);
    if (numberOfOperations == maxLength) {
      takeOldMember();
    }
  }

  /// Adds [value] at the end of the queue.
  void addLast(EasyOperation value) {
    numberOfOperations++;
    _operations.addLast(value);
    if (numberOfOperations == maxLength) {
      takeOldMember();
    }
  }

  /// Adds [value] at the end of the queue.
  void add(EasyOperation value) {
    numberOfOperations++;
    _operations.add(value);
    if (numberOfOperations >= maxLength) {
      takeOldMember();
    }
  }

  /// Removes a single instance of [value] from the queue.
  ///
  /// Returns `true` if a value was removed, or `false` if the queue
  /// contained no element equal to [value].
  bool remove(EasyOperation? value) {
    numberOfOperations--;
    return _operations.remove(value);
  }

  /// Adds all elements of [iterable] at the end of the queue. The
  /// length of the queue is extended by the length of [iterable].
  void addAll(Iterable<EasyOperation> iterable) {
    for (EasyOperation op in _operations) {
      if (_operations.length == maxLength) {
        takeOldMember();
      }
      _operations.add(op);
    }
  }

  /// Removes all elements in the queue. The size of the queue becomes zero.
  void clear() {
    numberOfOperations = 0;
    _operations.clear();
  }

  List<EasyOperation> toList() => <EasyOperation>[..._operations];
}
