import 'package:flutter/widgets.dart';
import 'package:easy_rich_editor/internal.dart';

@immutable
abstract class BaseComponentBuilder {
  Widget render(ComponentContext context);
  Future<Widget> renderAsync(ComponentContext context);
  void dispose();
}

class ComponentContext {
  final Node node;
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
