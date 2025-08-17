import 'package:flutter/foundation.dart';
import 'package:isolate_manager/isolate_manager.dart';
import 'package:meta/meta.dart';

import '../../../easy_rich_editor.dart';

typedef IsolateRunnable<Req, Res> = Res Function(Req req);
typedef IsolateCallback<Res> = void Function(Res res);

@internal
class IsolateRunner<Req, Res> {
  final String name;
  late bool _closed;

  bool isRunning = false;
  final bool restartIfAlreadyIsRunning;
  late IsolateManager<Res, Req>? _isolateManager;
  IsolateRunnable<Req, Res> runnable;

  IsolateRunner(
    this.name,
    this.runnable, {
    this.restartIfAlreadyIsRunning = false,
    int concurrent = 1,
  }) {
    _closed = false;
    _isolateManager = IsolateManager.create(
      runnable,
      concurrent: concurrent,
      queueStrategy: DropOldestStrategy(maxCount: 1),
    );
  }

  void run(Req req,
      {IsolateCallback<Res>? callback, bool useMainThreadIf = false}) async {
    if (_closed) {
      return;
    }
    if (isRunning && restartIfAlreadyIsRunning) {
      await _isolateManager?.restart();
      if (kDebugMode) {
        EasyEditorLogger.treeBackgroundRunners.warn(
          "Restarting computation to avoid "
          "ambiguous data modifications",
        );
      }
    }
    isRunning = true;
    if (useMainThreadIf) {
      final Res res = runnable.call(req);
      callback?.call(res);
      isRunning = false;
      return;
    }
    _isolateManager?.compute(req, callback: (message) async {
      if (_closed) {
        isRunning = false;
        return false;
      }
      callback?.call(message);
      isRunning = false;
      return true;
    });
  }

  bool get isClosed => _closed;

  void close() {
    _closed = true;
    _isolateManager?.stop();
    _isolateManager = null;
  }
}
