import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:isolate_manager/isolate_manager.dart';
import 'package:meta/meta.dart';

typedef IsolateRunnable<Req, Res> = Res Function(Req req);
typedef IsolateCallback<Res> = void Function(Res res);

@internal
class IsolateRunner<Req, Res> {
  final String name;
  late bool _closed;

  bool isRunning = false;
  final bool restartIfAlreadyIsRunning;
  late IsolateManager<Res, Req>? _isolateManager;

  IsolateRunner(
    this.name,
    IsolateRunnable<Req, Res> runnable, {
    this.restartIfAlreadyIsRunning = false,
  }) {
    _closed = false;
    _isolateManager = IsolateManager.create(
      runnable,
      concurrent: 1,
    );
  }

  void run(Req req, {IsolateCallback<Res>? callback}) async {
    if (_closed) {
      return;
    }
    if (isRunning && restartIfAlreadyIsRunning) {
      await _isolateManager?.restart();
      if (kDebugMode) {
        debugPrint(
          "Restarting "
          "computation since can't"
          " run the same "
          "function several times",
        );
      }
    }
    isRunning = true;
    _isolateManager?.compute(req, callback: (message) async {
      if (_closed) {
        return false;
      }
      callback?.call(message);
      isRunning = false;
      return true;
    });
  }

  void close() {
    _closed = true;
    _isolateManager?.stop();
    _isolateManager = null;
  }
}
