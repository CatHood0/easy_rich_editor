import 'package:easy_rich_editor/easy_rich_editor.dart';
import 'package:flutter_quill_delta_easy_parser/utils/nano_id_generator.dart';

import '../../../utils/background_isolate_runner/isolate_runner.dart';
import '../../core/indexer/tree_indexer.dart';

class IsolateTreeIndexer {
  IsolateTreeIndexer._();
  static final IsolateRunner<TreeIndexerPayload, TreeIndexerResult>
      isolateTreeIndexer = IsolateRunner<TreeIndexerPayload, TreeIndexerResult>(
    'main tree indexer',
    _indexTree,
    restartIfAlreadyIsRunning: true,
    concurrent: 1,
  );

  static final Map<String, IsolateRunner<TreeIndexerPayload, TreeIndexerResult>>
      _queue = <String, IsolateRunner<TreeIndexerPayload, TreeIndexerResult>>{};

  /// Close all the resources use by this class
  static void release() {
    isolateTreeIndexer.close();
    cleanIsolateQueueIfNeeded();
  }

  //TODO: document the new working of this method
  static IsolateRunner<TreeIndexerPayload, TreeIndexerResult> getSafeIsolate({
    String? id,
    bool forceReturningFromIdAlways = false,
    bool forceMainAlways = false,
  }) {
    if (isolateTreeIndexer.isRunning && !forceMainAlways ||
        forceReturningFromIdAlways) {
      cleanIsolateQueueIfNeeded();
      if (id != null && _queue[id] != null) {
        return _queue[id]!;
      }
      id ??= nanoid(4);
      final IsolateRunner<TreeIndexerPayload, TreeIndexerResult> newIsolate =
          IsolateRunner<TreeIndexerPayload, TreeIndexerResult>(
        'tree indexer for: $id',
        _indexTree,
        restartIfAlreadyIsRunning: true,
        concurrent: 1,
      );
      _queue[id] = newIsolate;
      return newIsolate;
    }
    return isolateTreeIndexer;
  }

  static void cleanIsolateQueueIfNeeded() {
    if (_queue.isNotEmpty) {
      final Map<String, IsolateRunner<TreeIndexerPayload, TreeIndexerResult>>
          remainingIsolates =
          <String, IsolateRunner<TreeIndexerPayload, TreeIndexerResult>>{};
      _queue.forEach((
        String id,
        IsolateRunner<TreeIndexerPayload, TreeIndexerResult> isolate,
      ) {
        if (isolate.isRunning) remainingIsolates[id] = isolate;
        if (!isolate.isClosed && !isolate.isRunning) {
          isolate.close();
        }
      });
      _queue.clear();
      if (remainingIsolates.isNotEmpty) {
        _queue.addAll(remainingIsolates);
      }
    }
  }

  @pragma('vm:entry-point')
  static TreeIndexerResult _indexTree(TreeIndexerPayload payload) {
    final Map<String, int> nodes = <String, int>{};
    if (payload.loadAfter < 0) {
      return TreeIndexerResult(nodes);
    }
    Node? node = payload.root.firstChild;
    int index = 0;
    while (node != null) {
      nodes[node.id] = index;
      node = node.next;
      index++;
    }
    return TreeIndexerResult(nodes);
  }
}
