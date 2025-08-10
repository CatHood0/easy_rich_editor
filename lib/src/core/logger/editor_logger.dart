import 'package:logging/logging.dart';

/// TODO: add documentation here 
class EasyEditorLogger {
  EasyEditorLogger._({
    required this.name,
  }) : _logger = Logger(name);

  final String name;
  late final Logger _logger;

  /// =================== TREE ==================== \\\
  static EasyEditorLogger tree = EasyEditorLogger._(name: 'tree');
  static EasyEditorLogger treeBackgroundRunners = EasyEditorLogger._(name: 'tree_background_runners');
  static EasyEditorLogger treeOperations = EasyEditorLogger._(name: 'tree_ops');
  static EasyEditorLogger treeFailures = EasyEditorLogger._(name: 'tree_failure');

  /// ================== Editor ================== \\\
  static EasyEditorLogger editor = EasyEditorLogger._(name: 'editor');

  static EasyEditorLogger operations = EasyEditorLogger._(name: 'operations');

  static EasyEditorLogger ime = EasyEditorLogger._(name: 'ime');

  static EasyEditorLogger selection = EasyEditorLogger._(name: 'selection');

  static EasyEditorLogger cursor = EasyEditorLogger._(name: 'cursor');
  static EasyEditorLogger scroll = EasyEditorLogger._(name: 'scroll');

  void error(String message) => _logger.severe(message);
  void warn(String message) => _logger.warning(message);
  void info(String message) => _logger.info(message);
  void debug(String message) => _logger.fine(message);
}
