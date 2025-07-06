import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_quill_delta_easy_parser/flutter_quill_delta_easy_parser.dart';
import 'package:easy_rich_editor/internal.dart';
import 'package:easy_rich_editor/easy_rich_editor.dart';
import 'package:meta/meta.dart';

@internal
final class Node extends LinkedListEntry<Node> {
  String type;
  Node? parent;
  late Map<String, dynamic> attributes = <String, dynamic>{};
  late final Object? value;
  late final String id;

  final LinkedList<Node> children = LinkedList<Node>();
  final GlobalKey<State> key = GlobalKey<State>();

  static String get rootId => 'root';

  /// We cache partially some things while we are processing them
  /// directly at this "box". This is cleaned automatically after
  /// put them into a `NodeChange` class
  static String get changeBoxKey => 'changed';

  Node({
    required this.type,
    required this.value,
    this.parent,
    Map<String, dynamic> attributes = const <String, dynamic>{},
    String? id,
    List<Node> children = const [],
  }) {
    this.id = id ?? nanoid(8);
    this.attributes = {...attributes};
    for (Node child in children) {
      if (child.parent != null) {
        child.unlink();
      }
      child.parent = this;
      children.add(child);
    }
  }

  Node.fromParagraph({
    String? id,
    this.type = ParagraphKeys.key,
    this.value,
    this.parent,
    required Paragraph paragraph,
  }) {
    assert(type.trim().isNotEmpty, 'type cannot be empty');
    this.id = id ?? paragraph.id;
    for (Line child in paragraph.lines) {
      final Node line = Node(
        type: ParagraphKeys.childrenKey,
        value: null,
        children: [],
        parent: this,
        id: child.id,
      );
      if (child.isNotEmpty) {
        for (TextFragment frag in child.fragments) {
          line.insertNode(
            Node(
              type: ParagraphKeys.textKey,
              value: frag.data,
              attributes: frag.attributes ?? {},
              parent: line,
            ),
          );
        }
      }
      insertNode(line);
    }
  }

  Node jumpToParent({bool Function(Node)? stopAt}) {
    if (parent == null || stopAt != null && stopAt(this)) {
      return this;
    }

    return parent!.jumpToParent(stopAt: stopAt);
  }

  int? _cachedLength;
  int? _cachedGlobalOffset;

  void invalidateCache() {
    _cachedLength = null;
    _cachedGlobalOffset = null;
  }

  int get length => _cachedLength ??= children.length;

  TextRange? computeGlobalOffset(Limiter limiter) {
    return null;
  }

  TextRange? computeNodeLength(Limiter limiter) {
    return null;
  }

  Node? get firstChild => isEmpty ? null : children.first;
  Node? firstWhere(bool Function(Node) expr) => children.firstWhereOrNull(expr);

  Node? get lastChild => isEmpty ? null : children.last;
  Node? lastWhere(bool Function(Node) expr) => children.lastWhereOrNull(expr);

  bool get isEmpty => length < 1;
  bool get isNotEmpty => !isEmpty;

  void insertNode(Node child, {int? path, bool after = false}) {
    if (child.parent != null && child.parent != this) {
      child.unlink();
      child.parent = null;
    }

    child.parent = this;

    if (path == null) {
      children.add(child);
      return;
    }

    final Node entry = children.elementAt(path);

    if (after && entry.next != null) {
      entry.next!.insertBefore(child);
      return;
    }

    entry.insertBefore(child);
  }

  // current path of this node
  int _path = -1;

  bool needsComputePath = true;

  /// Get the relative path to this node from its parent
  int get path {
    if (id == Node.rootId || type == Node.rootId) {
      return -1;
    }
    assert(
        parent != null,
        'to get a path '
        'for child "$id" needs a '
        'parent that wrap it');

    if (needsComputePath) {
      needsComputePath = false;
      final int lastPath = _path;
      for (int i = 0; i < parent!.length; i++) {
        Node child = parent!.children.elementAt(i);
        if (child.id == id) {
          _path = i;
          break;
        }
      }

      /// This never happen, since, when `needsComputePath`
      /// is `true`, it means that the Node was moved, and requires
      /// a new value to be catched
      if (_path == lastPath) {
        throw Exception(
          "Not found child(${id.substring(0, 6)}) in parent(${parent!.id.substring(0, 6)})",
        );
      }
    }

    return _path;
  }

  Node deepCopy() {
    return Node(
      type: type,
      value: value,
      id: id,
      parent: parent,
      children: [...children],
      attributes: {...attributes},
    );
  }

  Map<String, dynamic> getChangedValues() {
    return attributes[Node.changeBoxKey] ?? {};
  }

  void setChangedValues({
    String? textChange,
    Object? value,
    Map<String, dynamic>? attributesChange,
  }) {
    assert(
      attributes[Node.changeBoxKey] == null,
      "calling `setChangedValues` to add "
      "cached changes, must pass always the assert checking. "
      "This can happen when a "
      "change is not processed by the Tree, and it "
      "is cached undefinedly.",
    );

    attributes[Node.changeBoxKey] = {
      "text_change": textChange,
      "value": value,
      "attributes_change": attributesChange,
    };
  }

  Node updateValues(Map<String, dynamic> values) {
    String? text;
    Object? value;
    if (values["text_change"] != null) {
      text = values["text_change"] as String;
      assert(
        type == ParagraphKeys.textKey,
        "Tree is trying to "
        "apply changes into for ${ParagraphKeys.textKey} type "
        "into a $type type",
      );
    }
    if (values["value"] != null) {
      value = values["value"];
    }
    if (values["attributes_change"] != null) {
      final newAttributes = values["attributes_change"] as Map<String, dynamic>;
    }
    // here we need to take a look to verify some things
    return copyWith();
  }

  Node copyWith({
    String? type,
    String? id,
    Map<String, dynamic>? attributes,
    List<Node>? children,
    Node? parent,
    Object? value,
  }) {
    return Node(
      type: type ?? this.type,
      value: value ?? this.value,
      id: id ?? this.id,
      parent: parent ?? this.parent,
      children: children ?? [...this.children],
    );
  }

  set path(int path) {
    _path = path;
  }

  /// get a list reversed where the first element, is the root parent
  /// that contains this node
  List<int> get deepPath {
    if (parent == null) return [-1];

    final List<int> path = [this.path];

    Node? curParent = parent!;

    while (curParent != null) {
      path.add(curParent.path);
      curParent = curParent.parent;
    }

    return <int>[...path.reversed];
  }

  Map<String, dynamic> toJson() {
    return {
      "type": type,
      "id": id,
      "value": value,
      "attributes": attributes,
      "children": children,
    };
  }

  String toTreeString({int tab = 0}) {
    final StringBuffer buffer = StringBuffer("");
    buffer.write(" " * tab);
    buffer.writeln("$type: ");
    final int effectiveTab = tab + 1;
    for (var child in children) {
      buffer.write(" " * effectiveTab);
      buffer.writeln(child.toTreeString(tab: effectiveTab + 1));
    }
    return buffer.toString();
  }

  @visibleForTesting
  String dumpTreeStr({int tab = 0, List<int>? paths}) {
    paths ??= [];
    final Limiter? limiter = Tree.getLimiter(type);
    final StringBuffer buffer = StringBuffer("");
    buffer.writeln("$type(${id.substring(0, 4).trim()}-[$path]):");
    if (limiter == null || !limiter.shouldAvoidTraverseInto(this)) {
      for (int i = 0; i < length; i++) {
        // We need a way to add the other levels knowing
        // if them need a line (parent with more children
        // that the current one, must pass its level)
        for (int subPath in paths) {
          buffer.write(subPath == 0 ? "" : " " * (subPath));
          buffer.write("|");
        }
        // adding indenting for the
        buffer.write(" " * tab);
        buffer.write("|");
        final Node child = children.elementAt(i);
        if (i + 1 >= length) {
          buffer.write("_");
        }
        // add a separation between the guide lines
        // and the node
        buffer.write(" ");
        buffer.write(
          child.dumpTreeStr(
            tab: tab + 1,
            paths: i + 1 < length ? [...paths, tab] : paths,
          ),
        );
      }
    }
    if (value != null) {
      // We need a way to add the other levels knowing
      // if them need a line (parent with more children
      // that the current one, must pass its level)
      for (int subPath in paths) {
        buffer.write(subPath == 0 ? "" : " " * (subPath));
        buffer.write("|");
      }
      buffer.write(" " * tab);
      buffer.write("'");
      buffer.write(value.toString().replaceAll(RegExp('\n'), '\\n'));
      buffer.writeln("'");
    } else {
      buffer.writeln("");
    }
    return buffer.toString();
  }

  @override
  String toString() {
    return 'Node(type=$type,value=$value,attributes=$attributes,children=$children)';
  }
}
