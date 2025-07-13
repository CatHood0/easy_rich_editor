import 'package:easy_rich_editor/easy_rich_editor.dart';
import 'package:easy_rich_editor/src/tree_manager/core/cache_invalidator/node/node_paths_cache_invalidator.dart';
import 'package:flutter_quill_delta_easy_parser/utils/nano_id_generator.dart';
import '../../../../utils/background_isolate_runner/isolate_runner.dart';

class IsolateNodeCacheInvalidator {
  IsolateNodeCacheInvalidator._();
  static final IsolateRunner<NodePathCachePayload, NodePathCacheResult>
      isolateNodeCacheInvalidator =
      IsolateRunner<NodePathCachePayload, NodePathCacheResult>(
    'main nodes invalidator',
    _invalidateCacheOrReset,
    concurrent: 1,
  );

  /// Close all the resources use by this class
  static void release() {
    isolateNodeCacheInvalidator.close();
    cleanIsolateQueueIfNeeded();
  }

  static final Map<String,
          IsolateRunner<NodePathCachePayload, NodePathCacheResult>> _queue =
      <String, IsolateRunner<NodePathCachePayload, NodePathCacheResult>>{};

  //TODO: document the new working of this method
  static IsolateRunner<NodePathCachePayload, NodePathCacheResult>
      getSafeIsolate({
    String? id,
    bool forceReturningFromIdAlways = false,
  }) {
    if (forceReturningFromIdAlways) {
      cleanIsolateQueueIfNeeded();
      if (id != null && _queue[id] != null) {
        return _queue[id]!;
      }
      id ??= nanoid(4);
      final IsolateRunner<NodePathCachePayload, NodePathCacheResult>
          newIsolate = IsolateRunner<NodePathCachePayload, NodePathCacheResult>(
        'secundary invalidator for: $id',
        _invalidateCacheOrReset,
        restartIfAlreadyIsRunning: false,
        concurrent: 1,
      );
      _queue[id] = newIsolate;
      return newIsolate;
    }
    return isolateNodeCacheInvalidator;
  }

  static void cleanIsolateQueueIfNeeded() {
    if (_queue.isEmpty) return;
    final Map<String, IsolateRunner<NodePathCachePayload, NodePathCacheResult>>
        remainingIsolates =
        <String, IsolateRunner<NodePathCachePayload, NodePathCacheResult>>{};
    _queue.forEach((
      String id,
      IsolateRunner<NodePathCachePayload, NodePathCacheResult> isolate,
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

  @pragma('vm:entry-point')
  static NodePathCacheResult _invalidateCacheOrReset(
      NodePathCachePayload payload) {
    if (payload.path != -1) {
      // get the exact index to start the resetting
      int curPath = payload.after ? payload.path + 1 : payload.path - 1;
      Node? node = payload.after ? payload.node.next : payload.node.previous;
      while (node != null) {
        node.path = curPath;
        payload.after ? curPath++ : curPath--;
        node = payload.after ? node.next : node.previous;
      }
      return NodePathCacheResult();
    }
    Node? node = payload.root.firstChild;
    while (node != null) {
      node.invalidateCache();
      node = node.next;
    }
    return NodePathCacheResult();
  }
}
