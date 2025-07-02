import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_quill_delta_easy_parser/flutter_quill_delta_easy_parser.dart';
import 'package:flutter_quill_delta_easy_parser_visualizer/src/builders/paragraph/paragraph_keys.dart';
import 'package:meta/meta.dart';

@internal
final class EasyVilNode extends LinkedListEntry<EasyVilNode> {
  String type;
  EasyVilNode? parent;
  final LinkedList<EasyVilNode> children = LinkedList<EasyVilNode>();

  final GlobalKey<State> key = GlobalKey<State>();
  late Map<String, dynamic> attributes = <String, dynamic>{};
  late final Object? value;
  late final String id;

  EasyVilNode({
    required this.type,
    required this.value,
    this.parent,
    Map<String, dynamic> attributes = const <String, dynamic>{},
    String? id,
    List<EasyVilNode> children = const [],
  }) {
    this.id = id ?? nanoid(8);
    this.attributes = {...attributes};
    for (EasyVilNode child in children) {
      child.parent = this;
      children.add(child);
    }
  }

  EasyVilNode.fromParagraph({
    String? id,
    this.type = ParagraphKeys.key,
    this.value,
    required Paragraph paragraph,
  }) {
    assert(type.trim().isNotEmpty, 'type cannot be empty');
    for (Line child in paragraph.lines) {
      final EasyVilNode node = EasyVilNode(
        type: ParagraphKeys.childrenKey,
        value: null,
        children: [],
        parent: this,
        id: child.id,
      );
      for (TextFragment frag in child.fragments) {
        node.insertNode(
          EasyVilNode(
            type: ParagraphKeys.textKey,
            value: frag.data,
            attributes: frag.attributes ?? {},
            parent: node,
          ),
        );
      }
      insertNode(node);
    }
  }

  EasyVilNode jumpToParent({bool Function(EasyVilNode)? stopAt}) {
    if (parent == null || stopAt != null && stopAt(this)) {
      return this;
    }

    return parent!.jumpToParent(stopAt: stopAt);
  }

  int? _cachedLength = null;

  int get childrenLength => _cachedLength ??= children.length;

  EasyVilNode? get firstChild => _cachedLength == null ? null : children.first;
  EasyVilNode? firstWhere(bool Function(EasyVilNode) expr) =>
      children.firstWhereOrNull(
        expr,
      );

  EasyVilNode? get lastChild => _cachedLength == null ? null : children.last;
  EasyVilNode? lastWhere(bool Function(EasyVilNode) expr) =>
      children.lastWhereOrNull(
        expr,
      );

  bool get isEmpty => _cachedLength == null || _cachedLength! < 1;
  bool get isNotEmpty => !isEmpty;

  void insertNode(EasyVilNode child, {int? path, bool after = false}) {
    assert(child.parent == null,
        'child parent need to be null before inserting into another one');
    if (path == null) {
      children.add(child);
      return;
    }

    final EasyVilNode entry = children.elementAt(path);

    if (after && entry.next != null) {
      entry.next!.insertBefore(child);
      return;
    }

    entry.insertBefore(child);
  }

  // current path of this node
  int _path = -1;

  /// Get the relative path to this node from its parent
  int get path => _path;

  int get level => deepPath.length - 1;

  /// get a list reversed where the first element, is the root parent
  /// that contains this node
  List<int> get deepPath {
    if (parent == null) return [-1];

    final List<int> path = [this.path];

    EasyVilNode curParent = parent!;

    while (true) {
      path.add(curParent.path);
      if (curParent.parent == null) {
        break;
      }
      curParent = curParent.parent!;
    }

    return <int>[...path.reversed];
  }

  @internal
  set path(int path) {
    _path = path;
  }

  String toTreeString() {
    return '';
  }

  @override
  String toString() {
    return 'EasyVilNode(type=$type,value=$value,attributes=$attributes,children=$children)';
  }
}
