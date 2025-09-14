import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import '../../../../../easy_rich_editor.dart';

@internal
class FixedListLength {
  final QueueList<EasyOperation> _operations;
  late final int opsLength;
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
    opsLength = _operations.length;
  }

  FixedListLength.empty({
    this.maxLength = defaultMaxLength,
  }) : _operations = QueueList<EasyOperation>();

  /// Whether this stack is empty
  bool get isEmpty => opsLength <= 0;

  /// Whether this stack is not empty
  bool get isNotEmpty => !isEmpty;

  /// Removes and returns the first element of this queue.
  ///
  /// The queue must not be empty when this method is called.
  EasyOperation takeHead() {
    opsLength--;
    return _operations.removeLast();
  }

  /// Removes and returns the last element of the queue.
  ///
  /// The queue must not be empty when this method is called.
  EasyOperation takeOldMember() {
    opsLength--;
    return _operations.removeFirst();
  }

  /// Returns the most recent operation added
  EasyOperation? getRecent() {
    return _operations.lastOrNull;
  }

  /// Adds [value] at the beginning of the queue.
  void addFirst(EasyOperation value) {
    opsLength++;
    _operations.addFirst(value);
    if (opsLength == maxLength) {
      takeOldMember();
    }
  }

  /// Adds [value] at the end of the queue.
  void addLast(EasyOperation value) {
    opsLength++;
    _operations.addLast(value);
    if (opsLength == maxLength) {
      takeOldMember();
    }
  }

  /// Adds [value] at the end of the queue.
  void add(EasyOperation value) {
    opsLength++;
    _operations.add(value);
    if (opsLength >= maxLength) {
      takeOldMember();
    }
  }

  /// Removes a single instance of [value] from the queue.
  ///
  /// Returns `true` if a value was removed, or `false` if the queue
  /// contained no element equal to [value].
  bool remove(EasyOperation? value) {
    opsLength--;
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
    opsLength = 0;
    _operations.clear();
  }

  List<EasyOperation> toList() => <EasyOperation>[..._operations];
}
