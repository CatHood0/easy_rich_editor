import 'package:flutter/widgets.dart';
import 'package:easy_rich_editor/easy_rich_editor.dart';

import '../../internal.dart';

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
}
