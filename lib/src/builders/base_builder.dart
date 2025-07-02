import 'package:flutter/widgets.dart';
import 'package:flutter_quill_delta_easy_parser_visualizer/src/nodes/node.dart';

@immutable
abstract class BaseComponentBuilder {
  Widget render(ComponentContext context);
  Future<Widget> renderAsync(ComponentContext context);
  void dispose();
}

class ComponentContext {
  final EasyVilNode node;
  // The context associated to this Component
  final BuildContext context;
  /// The exact path where this node is
  final int path;

  ComponentContext({
    required this.node,
    required this.context,
    required this.path,
  });


}
