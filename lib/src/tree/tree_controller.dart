import 'package:flutter/widgets.dart';
import 'package:flutter_quill_delta_easy_parser_visualizer/src/limiters/limiter_base.dart';
import 'package:flutter_quill_delta_easy_parser_visualizer/src/nodes/node.dart';
import 'package:flutter_quill_delta_easy_parser_visualizer/src/tree/tree.dart';

/// This controller manages all the complex internal operations
/// like: text modifications
///
/// This controller is independent of the library architecture
/// since, it is just focused on manage the complex operations
/// and does not save any type of state or other type of functionalities
class TreeController extends ValueNotifier<Tree> {
  final Tree tree;

  TreeController({
    required this.tree,
  }) : super(tree);

  Limiter _getLimiter(String key) {
    final limiter = Tree.getLimiter(key);
    if (limiter == null) {
      throw UnsupportedError(
        'The node type $key has not '
        'limiter parent assigned yet. Ensure that all '
        'the nodes have its own limiter '
        'to avoid this warning',
      );
    }
    return limiter;
  }

  void insertText(EasyVilNode node, TextSelection selection) {
    // first get the root of this node
    final parent = node.jumpToParent();
    // get the limiter
    final limiter = _getLimiter(parent.type);
  }

  void updateText(EasyVilNode node) {}

  void deleteText(EasyVilNode node) {}
}
