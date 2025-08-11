part of 'package:easy_rich_editor/src/core/api/document/nodes/node.dart';

extension NodeExt on Node {
  RenderBox? get renderBox =>
      key.currentContext?.findRenderObject()?.castOrNull<RenderBox>();

  BuildContext? get context => key.currentContext;

  SelectableMixin? get selectable =>
      key.currentState?.castOrNull<SelectableMixin>();

  Rect get rect {
    if (renderBox != null) {
      final Offset boxOffset = renderBox!.localToGlobal(Offset.zero);
      return boxOffset & renderBox!.size;
    }
    return Rect.zero;
  }

  bool get hasDefinedValue => value != null && value is List<TextFragment>;
  bool get isBlockNode => metadata['block'] as bool? ?? !hasDefinedValue;

  bool get hasText =>
      value != null &&
      value is List<TextFragment> &&
      value!.cast<List<TextFragment>>().isNotEmpty &&
      value!.cast<List<TextFragment>>().first.data is String;

  bool get isBlankText =>
      value != null &&
      value is List<TextFragment> &&
      value!.cast<List<TextFragment>>().isEmpty;

  bool get isNotBlankText => !isBlankText;

  bool get hasEmbed =>
      value != null &&
      value is List<TextFragment> &&
      value!.cast<List<TextFragment>>().isNotEmpty &&
      value!.cast<List<TextFragment>>().first.data is Map<String, dynamic>;

  bool get isBlank => value == null;
}

extension NodeEquality on Iterable<Node> {
  bool equals(Iterable<Node> other) {
    if (length != other.length) {
      return false;
    }
    for (var i = 0; i < length; i++) {
      if (!_nodeEquals(elementAt(i), other.elementAt(i))) {
        return false;
      }
    }
    return true;
  }

  bool _nodeEquals<T, U>(T base, U other) =>
      identical(this, other) ||
      base is Node &&
          other is Node &&
          other.type == base.type &&
          other.children.equals(base.children);
}

extension NodeUtilities on Node {
  /// Determines if this Node has a direct value
  ///
  /// You can see this like the following diagram
  ///
  /// ```bash
  /// Paragraph
  ///  └─── Line
  ///
  /// # or
  ///
  /// Embed
  ///  └─── EmbedLine
  /// ```
  bool hasDirectValue() {
    return value != null ||
        value == null && length == 1 && firstChild!.value != null;
  }

  Node deepCopy() {
    return Node(
      id: id,
      type: type,
      value: value,
      parent: parent?.copyWith(),
      children: children.map<Node>((Node e) => e.deepCopy()).toList(),
      metadata: <String, dynamic>{...metadata},
    );
  }

  void forEach(void Function(Node node, int index) el) {
    if (isEmpty) return;

    int index = 0;
    for (int i = 0; i < length; i++) {
      final Node child = children[i];
      el(child, index);
      index++;
    }
  }

  Node copyWith({
    String? type,
    String? id,
    Map<String, dynamic>? metadata,
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

  Map<String, dynamic> toJson() {
    return {
      "type": type,
      "id": id,
      "value": value,
      "metadata": metadata,
      "children": children,
    };
  }

  @internal
  bool get isRootOwner =>
      id == Node.rootId ||
      type == Node.rootId ||
      metadata['root'] != null && metadata['root'] as bool;
}
