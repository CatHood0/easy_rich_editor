import 'package:easy_rich_editor/easy_rich_editor.dart';
import 'package:flutter_quill_delta_easy_parser/utils/nano_id_generator.dart';

import '../../utils/background_isolate_runner/isolate_runner.dart';
import '../core/indexer/tree_indexer.dart';

class IsolateTreeIndexer {
  IsolateTreeIndexer._();
  static final IsolateRunner<TreeIndexerPayload, TreeIndexerResult>
      isolateTreeIndexer = IsolateRunner<TreeIndexerPayload, TreeIndexerResult>(
    'main tree indexer',
    _indexTree,
    restartIfAlreadyIsRunning: true,
    // since this isolate should never
    // be called more than once time per re-index
    // we prefer just a isolate
    concurrent: 1,
  );

  static final Map<String, IsolateRunner<TreeIndexerPayload, TreeIndexerResult>>
      _queue = <String, IsolateRunner<TreeIndexerPayload, TreeIndexerResult>>{};

  /// Since the `IsolateRunner` that we use, is restarted if it is already running
  /// then we use this method to avoid closing an important operation:
  ///
  /// `getSafeIsolate` to get a new isolate instance if the main isolate is running already
  ///
  /// This method automatically make a cleanup of the isolates (close isolates
  /// that are not running, avoiding memory leaks)
  ///
  /// Note: We use `id` to ensure in some cases, that we can restart an isolate that is
  /// already updating a index tree at the same point that other one will start.
  ///   For index trees, we need to avoid running two isolates to make
  /// the same operation. With the `id` we can just pass the one from the Node,
  /// and the get isolate and restart it (if required) to avoid concurrent
  /// modifications of the index trees (and avoid ambiguous results)
  static IsolateRunner<TreeIndexerPayload, TreeIndexerResult> getSafeIsolate({
    String? id,
    bool forceReturningFromIdAlways = false,
    bool forceMainAlways = false,
  }) {
    if (isolateTreeIndexer.isRunning && !forceMainAlways ||
        forceReturningFromIdAlways) {
      if (id != null && _queue[id] != null) {
        return _queue[id]!;
      }
      id ??= nanoid(4);
      cleanIsolateQueueIfNeeded();
      final int index = _queue.length + 1;
      final IsolateRunner<TreeIndexerPayload, TreeIndexerResult> newIsolate =
          IsolateRunner<TreeIndexerPayload, TreeIndexerResult>(
        'tree indexer ${nanoid(index)}',
        _indexTree,
        restartIfAlreadyIsRunning: true,
        // since this isolate should never
        // be called more than once time per re-index
        // we prefer just a isolate
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
    for (int index = 0; index < payload.root.length; index++) {
      final Node node = payload.root.children.elementAt(index);
      nodes[node.id] = index;
    }
    return TreeIndexerResult(nodes);
  }
}
