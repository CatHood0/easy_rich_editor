part of 'easy_logger_configurations.dart';

extension on EasyLogLevel {
  Level toLevel() {
    switch (this) {
      case EasyLogLevel.off:
        return Level.OFF;
      case EasyLogLevel.error:
        return Level.SEVERE;
      case EasyLogLevel.warn:
        return Level.WARNING;
      case EasyLogLevel.info:
        return Level.INFO;
      case EasyLogLevel.debug:
        return Level.FINE;
      case EasyLogLevel.all:
        return Level.ALL;
    }
  }

  String get name {
    switch (this) {
      case EasyLogLevel.off:
        return 'OFF';
      case EasyLogLevel.error:
        return 'ERROR';
      case EasyLogLevel.warn:
        return 'WARN';
      case EasyLogLevel.info:
        return 'INFO';
      case EasyLogLevel.debug:
        return 'DEBUG';
      case EasyLogLevel.all:
        return 'ALL';
    }
  }
}

extension on Level {
  EasyLogLevel toLogLevel() {
    if (this == Level.SEVERE) {
      return EasyLogLevel.error;
    } else if (this == Level.WARNING) {
      return EasyLogLevel.warn;
    } else if (this == Level.INFO) {
      return EasyLogLevel.info;
    } else if (this == Level.FINE) {
      return EasyLogLevel.debug;
    }
    return EasyLogLevel.off;
  }
}
