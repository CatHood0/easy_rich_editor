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
    Logger.root.onRecord.listen((record) {
      if (handler != null) {
        handler!(
          '[${record.level.toLogLevel().name}][${record.loggerName}]: ${record.time}: ${record.message}',
        );
      }
    });
  }

  factory EasyLoggerConfiguration() => _logConfiguration;

  static final EasyLoggerConfiguration _logConfiguration =
      EasyLoggerConfiguration._();

  EasyLogHandler? handler;

  EasyLogLevel _level = EasyLogLevel.off;

  EasyLogLevel get level => _level;
  set level(EasyLogLevel level) {
    _level = level;
    Logger.root.level = level.toLevel();
  }
}
