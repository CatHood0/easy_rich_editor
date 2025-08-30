import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

part '_ext.dart';

@internal
enum EasyLogLevel {
  off,
  error,
  warn,
  info,
  debug,
  all,
}

typedef EasyLogHandler = void Function(String message);

/// Manages log service for [Tree]
///
/// Set the log level and config the handler depending on your need.
class EasyLoggerConfiguration {
  EasyLoggerConfiguration._() {
    Logger.root.onRecord.listen((
      LogRecord record,
    ) {
      if (handler != null) {
        handler!(
          '[${record.level.toLogLevel().name}]'
          '[${record.loggerName}]: '
          '${record.time}: '
          '${record.message}',
        );
      }
    });
  }

  factory EasyLoggerConfiguration() => instance;

  static final EasyLoggerConfiguration instance = EasyLoggerConfiguration._();

  EasyLogHandler? handler;

  EasyLogLevel _level = EasyLogLevel.off;

  EasyLogLevel get level => _level;

  void activeHandler({bool force = false}) {
    if (kDebugMode || force) {
      handler = debugPrint;
    }
  }

  void deactivateHandler() {
    if (handler != null) handler = null;
  }

  void all() {
    _level = EasyLogLevel.all;
    Logger.root.level = level.toLevel();
  }

  void debug() {
    _level = EasyLogLevel.debug;
    Logger.root.level = level.toLevel();
  }

  void info() {
    _level = EasyLogLevel.info;
    Logger.root.level = level.toLevel();
  }

  void warn() {
    _level = EasyLogLevel.warn;
    Logger.root.level = level.toLevel();
  }

  void off() {
    _level = EasyLogLevel.off;
    Logger.root.level = level.toLevel();
  }

  @internal
  set level(EasyLogLevel level) {
    _level = level;
    Logger.root.level = level.toLevel();
  }
}
