import 'dart:collection';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:easy_rich_editor/src/core/extensions/object_ext.dart';
import 'package:easy_rich_editor/src/logger/editor_logger.dart';
import 'package:easy_rich_editor/src/utils/background_isolate_runner/isolate_runner.dart';
import 'package:easy_rich_editor/src/utils/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_quill_delta_easy_parser/flutter_quill_delta_easy_parser.dart';
import 'package:easy_rich_editor/internal.dart';
import 'package:easy_rich_editor/easy_rich_editor.dart';
import 'package:meta/meta.dart';

part 'package:easy_rich_editor/src/core/extensions/nodes/node_ext.dart';
part 'package:easy_rich_editor/src/core/extensions/nodes/node_offset_ext.dart';
part 'package:easy_rich_editor/src/core/extensions/nodes/node_search_ext.dart';
part 'package:easy_rich_editor/src/core/extensions/nodes/node_printer_ext.dart';
part 'package:easy_rich_editor/src/core/extensions/nodes/node_operations_ext.dart';

final class Node extends LinkedListEntry<Node> {
  String type;
  Node? parent;
  late Map<String, dynamic> metadata = <String, dynamic>{};
  late final String id;

  final LinkedList<Node> children = LinkedList<Node>();
  final GlobalKey<State<StatefulWidget>> key =
      GlobalKey<State<StatefulWidget>>();
  final LayerLink nodeLink = LayerLink();

  /// A indexed version of this Node Tree Part (N.T.P) that must be always
  /// synced with the elements of the LinkedList, and must share the same
  /// memory reference for any instance (so, we never must put a copy
  /// of an instance here)
  final HashMap<String, Node> _fastIndexTreePart = HashMap();

  // Refer to https://www.fileformat.info/info/unicode/char/fffc/index.htm
  static const String kObjectReplacementCharacter = '\uFFFC';
  static const int kObjectReplacementInt = 65532;

  @internal
  static String get rootId => 'root';

  /// We cache partially some things while we are processing them
  /// directly at this "box". This is cleaned automatically after
  /// put them into a `NodeChange` class
  @internal
  static String get changeBoxKey => 'changed';

  Object? _value;
  int? _offset;

  /// The current length of the value into this Node
  int? _dataLength;

  /// The current length of the children list
  int? _cachedLength;
  // current path of this node
  int _path = -1;

  // current full path of this node
  List<int> _deepPath = <int>[-1];

  bool needsComputePath = true;
  bool needsComputeFullPath = true;

  Node.root({
    List<Node> children = const [],
    Map<String, dynamic>? metadata,
  })  : type = Node.rootId,
        parent = null,
        _value = null {
    metadata ??= <String, dynamic>{};
    id = rootId;
    type = rootId;
    this.metadata = {...metadata};
    adoptChildren(children);
  }

  Node({
    required this.type,
    required Object? value,
    this.parent,
    Map<String, dynamic>? metadata,
    String? id,
    bool canModifyChildrenLength = true,
    Map<String, dynamic>? blockAttributes,
    List<Node> children = const [],
  }) {
    this.value = value;
    this.id = id ?? nanoid(8);
    this.metadata = <String, dynamic>{...?metadata};
    this.metadata['can_modify_children_length'] = canModifyChildrenLength;
    adoptChildren(children);
    this.metadata['pr_attributes'] = blockAttributes;
  }

  Node.fromParagraphEmbed({
    String? id,
    Object? value,
    this.parent,
    required Paragraph paragraph,
  }) : type = EmbedKeys.key {
    this.value = value;
    assert(type.trim().isNotEmpty, 'type cannot be empty');
    assert(paragraph.isEmbed, 'the type of the Paragraph must be an Embed');
    this.id = id ?? paragraph.id;
    final List<Line> lines = paragraph.unsafeLines();
    for (int i = 0; i < lines.length; i++) {
      final Line child = lines[i];
      // normally, the `EmbedNodes` must have always
      // just a line and one fragment. But, since
      // we can also add our custom Embed with several
      // customizations, its better just allow saving them
      final Node line = Node(
        type: EmbedKeys.childrenKey,
        value: <TextFragment>[...child.fragments],
        children: [],
        parent: this,
        id: child.id,
        canModifyChildrenLength: false,
      );
      insertNode(line);
      _fastIndexTreePart[line.id] = line;
    }
    metadata['pr_attributes'] = paragraph.blockAttributes;
  }

  Node.fromParagraph({
    String? id,
    this.type = ParagraphKeys.key,
    Object? value,
    this.parent,
    required Paragraph paragraph,
  }) {
    assert(type.trim().isNotEmpty, 'type cannot be empty');
    this.id = id ?? paragraph.id;
    this.value = value;
    final List<Line> lines = paragraph.unsafeLines();
    for (int i = 0; i < lines.length; i++) {
      final Line line = lines[i];
      final Node lineNode = Node(
        type: ParagraphKeys.lineKey,
        // we will never accept new lines
        // as fragments
        value: paragraph.isNewLine || paragraph.isNewLineWithBlockAttributes
            ? <TextFragment>[]
            : <TextFragment>[
                ...line.fragments,
              ],
        children: <Node>[],
        parent: this,
        id: line.id,
        canModifyChildrenLength: false,
      );
      insertNode(lineNode);
      _fastIndexTreePart[lineNode.id] = lineNode;
    }
    metadata['pr_attributes'] = paragraph.blockAttributes;
  }

  Node.text({
    String? id,
    this.type = ParagraphKeys.key,
    Object? value,
    this.parent,
    required String text,
  }) {
    assert(type.trim().isNotEmpty, 'type cannot be empty');
    this.value = value;
    this.id = id ?? nanoid(8);
    if (text.contains(Utils.CR)) {
      final List<String> lines = LineSplitter().convert(text);
      for (int i = 0; i < lines.length; i++) {
        final String line = lines[i];
        final Node lineNode = Node(
          type: type,
          value: <TextFragment>[
            TextFragment(data: line),
          ],
          children: <Node>[],
          parent: this,
          canModifyChildrenLength: false,
        );
        insertNode(lineNode);
        _fastIndexTreePart[lineNode.id] = lineNode;
      }
      return;
    }

    final Node lineNode = Node(
      type: type,
      value: <TextFragment>[TextFragment(data: text)],
      children: <Node>[],
      parent: this,
      canModifyChildrenLength: false,
    );
    insertNode(lineNode);
  }

  /// Contents of this node, either a String if this is a [QuillText] or an
  /// [Embed] if this is an [BlockEmbed].
  Object? get value => _value;

  set value(Object? v) {
    _value = v;
    invalidateDataOffset();
  }

  int get dataLength {
    // This means that we are into a Parent
    if (!hasDefinedValue) {
      _dataLength ??= children.fold<int>(
        0,
        (int? prev, Node n) => (prev ?? 0) + n.dataLength,
      );
      return _dataLength!;
    }

    if (_value == null) return 0;
    if (_dataLength != null) return _dataLength!;
    if (_value is! List<TextFragment>) return _dataLength ??= 0;
    // we count all blank lines as new lines
    if (isBlankText) return _dataLength ??= 1;

    int length = 0;
    for (TextFragment frag in _value!.castToFragments()) {
      length += frag.isText ? frag.data.castString().length : 1;
    }

    return _dataLength = length;
  }

  bool get canAddOrRemovedChildren =>
      metadata['can_modify_children_length'] as bool? ?? true;

  bool get isReadOnly => metadata['read-only'] as bool? ?? false;

  void setReadonly() => metadata['read-only'] = true;

  void unSetReadonly() => metadata['read-only'] = false;

  void adoptChild(Node child, int path) {
    if (child.parent != null) child.unlink();
    child
      ..parent = this
      ..path = path;
    _fastIndexTreePart[child.id] = child;
    children.add(child);
  }

  void adoptChildren(List<Node> nodes) {
    for (int i = 0; i < nodes.length; i++) {
      final Node child = nodes[i];
      _fastIndexTreePart[child.id] = child;
      adoptChild(child, i);
    }
  }

  void invalidateDataOffset() {
    _dataLength = null;
    _offset = null;
    parent?.invalidateDataOffset();
  }

  /// When a node is added, moved, or deleted
  /// this function is called to avoid have an
  /// outdated cache.
  ///
  /// Normally, invalidates also the path
  /// but, since the path is just the current position
  /// into the list of its owner, then in some cases
  /// we don't need recompute the path really
  void invalidateCache({bool justCache = false}) {
    _cachedLength = null;
    if (!justCache) {
      needsComputePath = true;
      needsComputeFullPath = true;
    }
  }

  int get length => _cachedLength ??= children.length;

  Node? get firstChild => isEmpty ? null : children.first;
  Node? firstWhere(bool Function(Node) expr) => children.firstWhereOrNull(expr);

  Node? get lastChild => isEmpty ? null : children.last;
  Node? lastWhere(bool Function(Node) expr) => children.lastWhereOrNull(expr);

  /// Returns `true` if this node is the first node in the [parent] list.
  bool get isFirst => list!.first == this;

  /// Returns `true` if this node is the last node in the [parent] list.
  bool get isLast => list!.last == this;

  bool get isEmpty => length < 1;
  bool get isNotEmpty => !isEmpty;

  int get depthLevel => _deepPath.length - 1;

  /// Queries the child [Node] at [offset] in this [Node].
  ///
  /// The result may contain the found node or `null` if no node is found
  /// at specified offset.
  ///
  /// [NodeCursorPosLocation.fragmentIndex] is set to relative fragment index
  /// within returned child node
  ///
  /// [NodeCursorPosLocation.fragmentOffset] is set to relative offset into the fragments
  /// within returned child node which points at the same character position in the document
  ///
  /// [NodeCursorPosLocation.locationOffset] is set to relative offset within returned child node
  /// which points at the same character position in the document as the
  /// original [offset]
  // TODO: we can probably implement a fast version using
  // ranges to know for what node we should start to traverse
  NodeCursorPosLocation queryPosition(
    int cursorPos, {
    bool includeLastNode = false,
  }) {
    if (!isRootOwner && (cursorPos < 0 || cursorPos > dataLength)) {
      return NodeCursorPosLocation.notFound();
    }

    for (final Node node in children) {
      final int len = node.dataLength;
      // at this point, the cursor can be used
      // as a local position in the node, instead
      // a global one
      if (cursorPos < len ||
          (includeLastNode && cursorPos == len && node.isLast)) {
        // this means that we are in a `Node` of type `Line` or `EmbedLine`
        if (node.hasDefinedValue) {
          final List<TextFragment> frags = node.value!.castToFragments();
          int fragOffset = 0;
          for (int i = 0; i < frags.length; i++) {
            final TextFragment frag = frags[i];
            final int fragmentLength =
                frag.data is String ? frag.data.castString().length : 1;

            final int effectivePosition = fragOffset + fragmentLength;
            // if the cursor is in this exact fragment
            if (cursorPos < effectivePosition) {
              return NodeCursorPosLocation(
                location: NodeLocation(
                  path: <int>[...node.deepPath],
                  node: node,
                ),
                fragmentIndex: i,
                fragmentOffset: cursorPos - fragOffset,
                locationOffset: cursorPos,
              );
            }

            fragOffset += fragmentLength;
          }
        }

        return NodeCursorPosLocation(
          location: NodeLocation(path: <int>[...node.deepPath], node: node),
          fragmentIndex: -1,
          fragmentOffset: -1,
          locationOffset: cursorPos,
        );
      }
      cursorPos -= len;
    }

    return NodeCursorPosLocation.notFound();
  }

  /// Simplifies the insertion, it mades the operation directly at the node
  /// passed. The node passed must contain a value
  void insertAtNode(Node line, int offset, Object data, {int? endOffset}) {
    assert(line.value != null, 'node must contain a value to modify it');
  }

  /// Simplifies the deletion, it mades the operation directly at the node
  /// passed. The node passed must contain a value
  void deleteAtNode(Node line, int from, int to) {
    assert(line.value != null, 'node must contain a value to modify it');
  }

  void insert(int offset, Object data, {int? endOffset}) {}

  /// Retain is used commonly to apply styles into the subNodes
  void retain() {}

  void delete(int from, int to) {}

  @override
  void insertAfter(Node entry) {
    if (!canAddOrRemovedChildren) return;
    // since we insert an element after this
    // the path changes, and we need a new reallocation
    int lastPathKnowed = _path;
    super.insertAfter(entry);
    final List<int> effectiveDeepPath = <int>[..._deepPath];
    _deepPath[_deepPath.length - 1] = _path + 1;
    entry
      ..parent = parent
      // to avoid recomputing of a knowed path
      // just set it
      ..path = lastPathKnowed++
      ..deepPath = effectiveDeepPath;
    invalidateCache();
    _fastIndexTreePart[entry.id] = entry;
    if (entry.next != null) {
      // reset the current path of the node
      invalidateCacheOfSiblings(
        node: entry,
        after: true,
        curPath: entry.path,
      );
    }
  }

  @override
  void insertBefore(Node entry) {
    if (!canAddOrRemovedChildren) return;
    // since we insert an element before this
    // the path changes, and we need a new reallocation
    int lastPathKnowed = _path;
    super.insertBefore(entry);
    entry
      ..parent = parent
      // to avoid recomputing of a knowed path
      // just set it
      ..path = lastPathKnowed
      ..deepPath = <int>[..._deepPath];
    invalidateCache();
    lastPathKnowed++;
    final List<int> effectiveDeepPath = <int>[..._deepPath]
      ..[_deepPath.length - 1] = _path + 1;
    path = lastPathKnowed;
    deepPath = effectiveDeepPath;
    _fastIndexTreePart[entry.id] = entry;
    if (next != null) {
      // reset the current path of the node
      invalidateCacheOfSiblings(
        node: this,
        after: true,
        curPath: lastPathKnowed,
      );
    }
  }

  @override
  void unlink() {
    super.unlink();
    if (parent != null) {
      parent!._removeCached(this);
      parent = null;
      invalidateCache();
    }
  }

  void updatePathsIfNeeded(int path, List<int> fullPath) {
    if (needsComputePath && path != -1) {
      path = path;
    }
    if (needsComputeFullPath && fullPath.isNotEmpty) {
      deepPath = fullPath;
    }
  }

  /// Get the relative path to this node from its parent
  int get path {
    if (id == Node.rootId || type == Node.rootId) {
      return -1;
    }

    if (!needsComputePath || parent == null) return _path;

    assert(
        parent != null,
        'to get a path '
        'for child "$id" needs a '
        'parent that wrap it');

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

    return _path;
  }

  set path(int path) {
    _path = path;
    needsComputePath = false;
  }

  set deepPath(List<int> path) {
    _deepPath = <int>[...path];
    needsComputeFullPath = false;
  }

  /// Get a normalized list of paths where this Node is
  List<int> get deepPath {
    if (!needsComputeFullPath) return _deepPath;
    if (parent == null) return [];

    final List<int> path = [this.path];

    Node? curParent = parent!;

    while (curParent != null) {
      // we ignore always the root
      if (curParent.id == Node.rootId) {
        break;
      }
      path.add(curParent.path);
      curParent = curParent.parent;
    }

    _deepPath = <int>[...path.reversed];

    return _deepPath;
  }

  @internal
  Node updateValues(Map<String, dynamic> values, bool isText) {
    if (values["text_change"] != null) {
      final String text = values["text_change"] as String;
      assert(
        !isText,
        "Tree is trying to "
        "apply changes into for valid text types "
        "into a $type type",
      );
      value = text;
    }
    if (values["value"] != null) {
      value = values["value"];
    }
    if (values["attributes_change"] != null) {
      final newAttributes = values["attributes_change"] as Map<String, dynamic>;
      metadata = {...metadata, ...newAttributes};
    }
    // here we need to take a look to verify some things
    return this;
  }

  void _removeCached(Node node) {
    _fastIndexTreePart.remove(node.id);
  }

  @internal
  @pragma('vm:entry-point')
  void invalidateCacheOfSiblings({
    required bool after,
    required Node node,
    int curPath = -1,
  }) {
    assert(parent != null || isRootOwner,
        "Must have a parent to invalidate cache of siblings");

    final NodePathCachePayload payload = NodePathCachePayload(
      root: parent ?? this,
      node: node,
      path: curPath,
      after: after,
    );

    final IsolateRunner<NodePathCachePayload, NodePathCacheResult> isolate =
        IsolateNodeCacheInvalidator.getSafeIsolate(
      id: id,
      forceReturningFromIdAlways: true,
    );
    if (kDebugMode) {
      EasyEditorLogger.treeBackgroundRunners
          .debug("Params for resetting paths: ${{
        "parent": parent?.id,
        "currentNode": node.id,
        "last_path": curPath,
        "after": after,
      }}");
    }

    isolate.run(
      payload,
      callback: (NodePathCacheResult result) {},
    );
  }

  // =================== NOTE ===================
  // We dont implement a custom equals and hashcode
  // that uses all the class attributes, because them
  // can create a circular loop and aftera stack
  // overflow.
  @override
  bool operator ==(covariant Node other) {
    if (identical(this, other)) return true;
    return id == other.id;
  }

  @override
  int get hashCode => Object.hashAllUnordered(<Object?>[
        id,
      ]);

  @override
  String toString() {
    return 'Node(type=$type,value=$value,metadata=$metadata,children=$children)';
  }
}
