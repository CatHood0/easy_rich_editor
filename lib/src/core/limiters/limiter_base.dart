import 'package:easy_rich_editor/internal.dart';

abstract class Limiter {
  /// Get the algorithm that should we use to resolve traversing into this
  /// limit
  ///
  /// Must be in order of which key is the parent of the rest,
  /// and which is the key that is the most deeper child
  ///
  /// For example, for paragraph
  /// we should just traversing 3 levels, no more, and no less
  ///
  /// Defining a depth like:
  ///
  /// ```dart
  ///  @override
  ///  List<String> get dephtLimit => [
  ///       ParagraphKeys.key,
  ///       ParagraphKeys.childrenKey,
  ///       ParagraphKeys.textKey,
  ///  ];
  /// ```
  ///
  /// Can be represented by this simple diagram
  ///
  /// ```bash
  /// Paragraph
  /// │  Line 1
  /// │  └─── Text
  /// └─ Line 2
  ///    └─── Text
  /// ```
  //TODO: should we change this to a Map for a improve the access?
  List<String> get depthLimit;

  int get maxDepth => depthLimit.length;

  /// The root node what is based this limiter
  String get limiterParentOf;

  int maxDepthLevelToGetData(Node root) {
    int depthCount = 0;

    void depth(Node child) {
      final firstChild = child.firstWhere((node) => node.isNotEmpty);
      if (firstChild == null) {
        /// treelogger.warn(treelogger.warn, "there is no node to get depth info")
        depthCount = 0;
        return;
      }

      if (firstChild.type == depthLimit[maxDepth - 1]) {
        return;
      }

      depthCount++;
      depth(firstChild);
    }

    if (root.isNotEmpty) {
      depth(root);
    }
    return depthCount;
  }

  /// Determines if we can go more deeper than where we are
  bool shouldAvoidTraverseInto(Node node);
}
