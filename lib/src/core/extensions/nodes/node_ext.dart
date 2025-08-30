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

  /// Whether this [Node]  has defined it's value
  bool get hasDefinedValue => value != null;

  /// Whether this [Node] is a block (a container of children lines)
  bool get isBlockNode => metadata['block'] as bool? ?? !hasDefinedValue;

  /// Whether this [Node] has some text into
  bool get hasText =>
      supportEasyText && texts.isNotEmpty && texts.first.text.isNotEmpty;

  /// Whether this [Node] hasn't some text into
  bool get hasNoText =>
      supportEasyText &&
      (texts.isEmpty || texts.length == 1 && texts.first.text.isEmpty);

  /// Whether this [Node] has [TextFragment] content
  bool get hasEmbed =>
      supportEmbed &&
      value.castToFragment().data is Map<String, dynamic> &&
      value.castToFragment().data.cast<Map<String, dynamic>>().isNotEmpty;

  /// Whether this [Node] has not [TextFragment] content
  bool get hasNoEmbed =>
      supportEmbed &&
      (value == null ||
          value.castToFragment().data.cast<Map<String, dynamic>>().isEmpty);

  /// Whether this [Node] supports [EasyText] and [EasyTextList]
  bool get supportEasyText =>
      isLineBlock || value != null && value is EasyTextList;

  /// Whether this [Node] support [TextFragment] content
  bool get supportEmbed =>
      isEmbedLine || value != null && value is TextFragment;

  /// Whether this [Node] supports is fully empty
  bool get isBlankOrEmpty => isEmbedLine ? !hasEmbed : isBlankText;

  /// Whether this [Node] is [Embed]
  bool get isEmbedBlock => type == EmbedKeys.key;

  /// Whether this [Node] is [EmbedLine]
  bool get isEmbedLine => type == EmbedKeys.childrenKey;

  /// Whether this [Node] is [Paragraph]
  bool get isParagraphBlock => type == ParagraphKeys.key;

  /// Whether this [Node] is [Line]
  bool get isLineBlock => type == ParagraphKeys.lineKey;

  /// Whether this [Node] is blank
  bool get isBlankText => supportEasyText && texts.isEmpty;

  /// Whether this [Node] is strictly blank (text must be single or empty)
  bool get isStrictlyBlankText =>
      supportEasyText &&
      (texts.isEmpty || texts.length == 1 && !texts.first.hasText);

  /// Whether this [Node] is not blank
  bool get isNotBlankText => !isBlankText;

  EasyTextList get texts => value.castToEasyText();

  /// Whether this [Node] has no value into itself
  bool get isBlank => isEmbedLine ? hasNoEmbed : isBlankText;

  /// Whether this [Node] has value into it
  bool get isNotBlank => isEmbedLine ? hasEmbed : isNotBlankText;

  /// Whether this [Node] has no value hasDefined
  bool get isStrictlyBlank => isEmbedLine ? hasEmbed : isStrictlyBlankText;

  /// Whether this [Node] has value defined and must satisfy some strict
  /// conditions
  bool get isNotStrictlyBlank => isEmbedLine ? hasEmbed : !isStrictlyBlankText;

  @internal
  void get assertRoot {
    assert(isRootOwner, 'The node ${shortInfo()} is not the expected');
  }
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
    Object? v;
    if (supportEasyText) {
      v = EasyTextList()
        ..addAll(
          texts.map<EasyText>(
            (EasyText n) => n.copyWith(),
          ),
        );
    }
    v ??= value;
    return Node(
      id: id,
      type: type,
      value: v,
      parent: parent?.copyWith(),
      children: <Node>[...children.map<Node>((Node e) => e.deepCopy())],
      metadata: <String, dynamic>{...metadata},
      blockAttributes: blockAttributes,
      canModifyChildrenLength: canAddOrRemovedChildren,
    )
      ..path = path
      ..deepPath = deepPath
      ..text = text
      ..dataLength = dataLength;
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
}
