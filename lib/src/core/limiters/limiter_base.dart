import 'package:easy_rich_editor/easy_rich_editor.dart';

/// Limiters are our way to know how are composed every Node
///
/// Normally, every Limiter is defined by the Node type, to
/// optimize all the queries into the Nodes. Them tells to you
/// if is convenient traversing into a particular node, or what
/// is level where we can found the text values (or objects for the embeds)
abstract class Limiter {
  /// Get the algorithm that should we use to resolve traversing into this
  /// limit
  ///
  /// Must be in order of which key is the parent of the rest,
  /// and which is the key that is the most deeper child
  ///
  /// For example, for paragraph
  /// we should just traversing 2 levels, no more, and no less
  ///
  /// Defining a depth like:
  ///
  /// ```dart
  ///  @override
  ///  List<String> get dephtLimit => [
  ///       ParagraphKeys.key,
  ///       ParagraphKeys.childrenKey,
  ///  ];
  /// ```
  ///
  /// Can be represented by this simple diagram
  ///
  /// ```bash
  /// Paragraph
  /// │  Line 1: [Text, Text]
  /// │  
  /// └─ Line 2: [Text]
  ///    
  /// ```
  //TODO: should we change this to a Map for a improve the access?
  List<String> get depthLimit;

  Type get typeValueAccepted;

  int get maxDepth => depthLimit.length;

  /// The root node what is based this limiter
  String get limiterParentOf;

  /// Determine if the type of the Node can have
  /// a value
  bool typeCanContainValue(String type);

  /// Determine if the the Node can have a value
  bool ignoreByEmptyValueOrInvalid(Node node);

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
