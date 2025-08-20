import 'dart:collection';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:easy_rich_editor/src/core/api/document/path/path.dart';
import 'package:easy_rich_editor/src/core/api/editor_state/easy_state.dart';
import 'package:easy_rich_editor/src/core/extensions/object_ext.dart';
import 'package:easy_rich_editor/src/utils/background_isolate_runner/isolate_runner.dart';
import 'package:easy_rich_editor/src/utils/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_quill_delta_easy_parser/flutter_quill_delta_easy_parser.dart';
import 'package:easy_rich_editor/internal.dart';
import 'package:easy_rich_editor/easy_rich_editor.dart';
import 'package:meta/meta.dart';

import '../../../../editor/common/selectable_mixin.dart';

part 'package:easy_rich_editor/src/core/extensions/fragments/node_fragment_modifier_extension.dart';
part 'package:easy_rich_editor/src/core/extensions/nodes/node_ext.dart';
part 'package:easy_rich_editor/src/core/extensions/nodes/node_offset_ext.dart';
part 'package:easy_rich_editor/src/core/extensions/nodes/node_search_ext.dart';
part 'package:easy_rich_editor/src/core/extensions/nodes/node_printer_ext.dart';
part 'package:easy_rich_editor/src/core/extensions/nodes/node_operations_ext.dart';

final class Node extends ChangeNotifier {
  String type;
  Node? parent;
  late Map<String, dynamic> metadata = <String, dynamic>{};
  late final String id;

  final List<Node> children = <Node>[];
  final GlobalKey<State<StatefulWidget>> key =
      GlobalKey<State<StatefulWidget>>();
  final LayerLink nodeLink = LayerLink();

  /// A indexed version of this Node Tree Part (N.T.P) that must be always
  /// synced with the elements of the LinkedList, and must share the same
  /// memory reference for any instance (so, we never must put a copy
  /// of an instance here)
  final HashMap<String, Node> _fastIndexTreePart = HashMap<String, Node>();

  // Refer to https://www.fileformat.info/info/unicode/char/fffc/index.htm
  static const String kObjectReplacementCharacter = '\uFFFC';
  static const int kObjectReplacementInt = 65532;

  @internal
  static String get rootId => 'root';

  static const int _notFoundPath = -1;

  //FIXME: implement this
  String? _text;
  Object? _value;

  /// Offset only works for parents like [Paragraph], [Embed], or [Table]
  /// Since we want to avoid caching the relative offsets of the [Lines]
  int? _offset;

  /// The current length of the value into this Node
  int? _dataLength;

  /// The current length of the children list
  int? _cachedLength;
  // current path of this node
  int _path = -1;

  // current full path of this node
  NodeDepthPath _deepPath = <int>[];

  bool needsComputePath = true;
  bool needsComputeFullPath = true;

  Node.root({
    List<Node> children = const <Node>[],
    Map<String, dynamic>? metadata,
  })  : type = Node.rootId,
        id = Node.rootId,
        parent = null,
        _value = null {
    metadata ??= <String, dynamic>{};
    this.metadata = <String, dynamic>{
      ...metadata,
      'root': true,
      'block': false,
    };
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
    List<Node> children = const <Node>[],
  }) {
    this.value = value;
    this.id = id ?? EasyTreeState.createNodeId();
    this.metadata = <String, dynamic>{...?metadata};
    this.metadata['can_modify_children_length'] = canModifyChildrenLength;
    this.metadata['block'] = value == null;
    if (canModifyChildrenLength) this.metadata['block'] = true;
    adoptChildren(children);
    this.metadata['pr_attributes'] = blockAttributes;
  }

  Node.fromParagraphEmbed({
    String? id,
    this.parent,
    required Paragraph paragraph,
  }) : type = EmbedKeys.key {
    assert(paragraph.isEmbed, 'the type of the Paragraph must be an Embed');
    value = null;
    metadata
      ..['block'] = true
      ..['pr_attributes'] = paragraph.blockAttributes;
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
        children: <Node>[],
        parent: this,
        id: child.id,
        canModifyChildrenLength: false,
      );
      insertNode(line);
      _fastIndexTreePart[line.id] = line;
    }
  }

  Node.fromParagraph({
    String? id,
    this.type = ParagraphKeys.key,
    this.parent,
    required Paragraph paragraph,
  }) {
    assert(!paragraph.isEmbed, 'Paragraph cannot be Embed. Found: $paragraph');
    this.id = id ?? paragraph.id;
    _value = null;
    metadata
      ..['block'] = true
      ..['pr_attributes'] = paragraph.blockAttributes
      ..['can_modify_children_length'] = true;
    final List<Line> lines = paragraph.unsafeLines();
    for (int i = 0; i < lines.length; i++) {
      final Line line = lines[i];
      final Node lineNode = Node(
        type: ParagraphKeys.lineKey,
        // we will never accept new lines
        // as fragments
        value: (line.isNewLine)
            ? <TextFragment>[TextFragment.empty()]
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
  }

  Node.embedChild({
    String? id,
    this.parent,
    Map<String, dynamic>? metadata,
    Map<String, dynamic>? blockAttributes,
    Object? data,
  }) : type = EmbedKeys.childrenKey {
    assert(data == null || data is! String,
        'Only non embed blocks can have text data');
    this.id = id ?? EasyTreeState.createNodeId();
    this.metadata = <String, dynamic>{
      'block': true,
      'pr_attributes': blockAttributes,
      'can_modify_children_length': false,
      ...?metadata,
    };
    _value = data == null
        ? <TextFragment>[]
        : <TextFragment>[TextFragment(data: data)];
    _dataLength = data == null ? 0 : 1;
    _text = data == null ? null : Node.kObjectReplacementCharacter;
  }

  Node.embedBlock({
    String? id,
    this.parent,
    Map<String, dynamic>? metadata,
    Map<String, dynamic>? blockAttributes,
    Object? data,
  }) : type = EmbedKeys.key {
    assert(data == null || data is! String,
        'Only non embed blocks can have text data');
    this.id = id ?? EasyTreeState.createNodeId();
    this.metadata = <String, dynamic>{
      'block': true,
      'pr_attributes': blockAttributes,
      'can_modify_children_length': true,
      ...?metadata,
    };
    final Node lineNode = Node(
      type: EmbedKeys.childrenKey,
      value: data == null
          ? <TextFragment>[]
          : <TextFragment>[TextFragment(data: data)],
      parent: this,
      canModifyChildrenLength: false,
    )..text = data?.text();
    text = data?.text();
    insertNode(lineNode);
  }

  Node.block({
    String? id,
    this.parent,
    this.type = ParagraphKeys.key,
    String childType = ParagraphKeys.lineKey,
    Map<String, dynamic>? metadata,
    Map<String, dynamic>? blockAttributes,
    List<Node> children = const <Node>[],
    Object? data,
    bool noInvalidation = false,
  }) {
    assert(type.trim().isNotEmpty, 'type cannot be empty');
    assert(childType.trim().isNotEmpty, 'childType cannot be empty');
    assert(
        data == null || data is String,
        'Only embed blocks can '
        'contain objects of type ${data.runtimeType}');
    this.id = id ?? EasyTreeState.createNodeId();
    this.metadata = <String, dynamic>{
      'block': true,
      'pr_attributes': blockAttributes,
      ...?metadata,
    };
    //FIXME: implement a better search to know if the
    // text contains new lines
    if (data != null) {
      if (data.castString().contains(Utils.CR)) {
        final List<String> lines = LineSplitter().convert(data.castString());
        for (int i = 0; i < lines.length; i++) {
          final String line = lines[i];
          final Node lineNode = Node(
            type: childType,
            value: <TextFragment>[
              TextFragment(data: line),
            ],
            children: <Node>[],
            parent: this,
            canModifyChildrenLength: false,
          )..text = line;
          text = nsText == null ? line : '${nsText.orEmpty}\n$line';
          insertNode(lineNode);
        }
        adoptChildren(children);
        return;
      }

      final Node lineNode = Node(
        type: childType,
        value: <TextFragment>[TextFragment(data: data.castString())],
        children: <Node>[],
        parent: this,
        canModifyChildrenLength: false,
      )..text = data.castString();
      text = data.castString();
      insertNode(lineNode);
    }
    adoptChildren(children);
  }

  Object? get value => _value;

  /// Notify to all listeners about the changes in this [Node]
  ///
  /// Use it to force rebuilds if it requires
  void notify() {
    notifyListeners();
  }

  Node? get next => isLast ||
          parent == null ||
          path == -1 ||
          !parent!.contains(id) ||
          path.next >= parent!.length
      ? null
      : parent!.elementAtOrNull(path.next);

  Node? get previous =>
      isFirst || parent == null || path.prev < 0 || path.prev >= parent!.length
          ? null
          : parent!.elementAtOrNull(path.prev.nonNegative);

  set value(Object? v) {
    _value = v;
    _dataLength = null;
    _text = null;
    parent?.invalidateDataOffset();
  }

  @internal
  void setDataLength(int? dataLength, {bool invalidate = true}) {
    if (_dataLength == dataLength) return;
    _dataLength = dataLength;
    _text = null;
    if (invalidate) {
      parent?.invalidateDataOffset();
    }
  }

  /// Returns the current plain text cached in this [Node]
  String get text => _text ??= toPlainText();

  /// Modifies the value in this [Node]
  /// but not invalidates any cache at
  /// this one or the parent
  set nsValue(Object? v) {
    _value = v;
  }

  /// Returns the current plain text cached in this [Node]
  ///
  /// The difference between the [text] getter, is this
  /// returns the direct value, without computing the
  /// plain text when required
  String? get nsText => _text;

  int? get nsDataLength => _dataLength;

  /// Set the nullable text passed to the cache property
  set text(String? text) {
    _text = text;
  }

  set dataLength(int? dataLength) {
    if (_dataLength == dataLength) return;
    _dataLength = dataLength;
  }

  void overrideChild(int path, Node node, {bool removeRegistries = true}) {
    if (!canAddOrRemovedChildren) return;
    RangeError.checkValidIndex(path, children);
    final Node old = elementAt(path);
    if (removeRegistries && old.id != node.id) {
      _fastIndexTreePart
        ..remove(old.id)
        ..[node.id] = node;
    }
    dataLength = (dataLength - old.dataLength) + node.dataLength;
    if (_text != null) {
      text = text.replaceRange(
        old.offset,
        old.endOffset,
        node.text,
      );
    }

    old.unlink();
    children[path] = node;
    final Node root = jumpToParent();
    if (root.isRootOwner) {
      root
        ..rebuildNodes(
          changes: old.isBlockNode
              ? <String, int>{
                  old.id: 0,
                  node.id: 2,
                }
              : <String, int>{
                  node.jumpToParentExceptRoot()!.id: 1,
                },
        )
        ..notify();
    }
  }

  int get dataLength {
    // This means that we are into a Parent
    if (isBlockNode || isRootOwner) {
      _dataLength ??= children
          .fold<int>(
            0,
            (int prev, Node n) => prev + n.dataLength,
          )
          .incr;
      // required to let the end of the node to
      // be selected by query methods
      return _dataLength!;
    }

    if (_dataLength != null) return _dataLength!;
    if (_value is! List<TextFragment>) {
      throw Exception('Only List<TextFragment> are accepted');
    }

    int length = 0;
    for (TextFragment frag in _value!.castToFragments()) {
      length += frag.length;
      if (_text == "" || _text == null) {
        _text = "${_text.orEmpty}"
            "${frag.text(ifNot: Node.kObjectReplacementCharacter)}";
      }
    }
    return _dataLength = length;
  }

  String toPlainText({String Function(Node node, Object fr)? embedBuilder}) {
    if (_text != null) return _text!;
    final StringBuffer buffer = StringBuffer();
    if (isBlockNode || !hasDefinedValue) {
      for (final Node node in children) {
        buffer.write(node.toPlainText(embedBuilder: embedBuilder));
      }
      _text = '$buffer';
      return _text!;
    }

    int length = 0;
    for (TextFragment frag in _value!.castToFragments()) {
      if (_dataLength == null) {
        length += frag.length;
      }
      final String obj = frag.text(
        ifNotBuilder: embedBuilder == null
            ? null
            : (Object e) => embedBuilder(
                  this,
                  e,
                ),
      );
      buffer.write(obj);
    }
    _dataLength ??= length;
    return _text = '$buffer';
  }

  List<Node> subChildren(int start, [int? end]) {
    return children.sublist(start, end);
  }

  /// Notifies the render editor of specific nodes that have changed their values.
  ///
  /// This method is particularly useful when you need to re-render only specific
  /// components without recalculating all cached components, improving performance
  /// by avoiding unnecessary computations.
  ///
  /// The [changes] parameter is a map where:
  /// - Keys are node IDs (String)
  /// - Values are integers indicating the change type:
  ///   - `0`: Node removal            - removes the cached render paragraph instance
  ///   - `1`: Node addition or update - indicates a new node was added
  ///   - `2`: Node replace            - indicates the node that was removed, is replaced by node
  ///                                     if replace notify has no node removal, then render editor
  ///                                     ignores it
  ///
  /// Example:
  /// ```dart
  /// // Remove a node from cache
  /// root
  ///   ..rebuildNodes({node.id: 0})
  ///   ..notify();
  ///
  /// // Add or notify about changes in node
  /// root
  ///   ..rebuildNodes({node.id: 1})
  ///   ..notify();
  ///
  /// // Add a new node
  /// root
  ///   ..rebuildNodes({node.id: 0, replace.id: 2})
  ///   ..notify();
  /// ```
  @internal
  void rebuildNodes({Map<String, int>? changes, bool shouldNotify = false}) {
    assert(isRootOwner, 'Only root node can set a list of changes');
    // merge new changes with the current ones
    // if required
    //
    // Tipically this never happen, since render
    // editor, clear automatically after render
    if (hasChanges && changes != null) {
      metadata[Node.requireRebuildKey] =
          HashMap<String, int>.from(<String, int>{
        ...this.changes!,
        ...changes,
      });
      if (shouldNotify) notify();
      return;
    }
    metadata[Node.requireRebuildKey] =
        changes == null ? null : HashMap<String, int>.from(changes);
    if (shouldNotify) notify();
  }

  @internal
  static const String requireRebuildKey = 'requires_build';

  bool get canAddOrRemovedChildren =>
      metadata['can_modify_children_length'] as bool? ?? true;

  @internal
  bool get hasChanges =>
      isRootOwner && (changes != null && changes!.isNotEmpty);

  @internal
  HashMap<String, int>? get changes =>
      metadata[Node.requireRebuildKey] as HashMap<String, int>?;

  Map<String, dynamic>? get blockAttributes =>
      metadata['pr_attributes'] as Map<String, dynamic>?;

  bool get isReadOnly => metadata['read-only'] as bool? ?? false;

  void setReadonly() => metadata['read-only'] = true;

  void unSetReadonly() => metadata['read-only'] = false;

  bool swapNodes(Node node, int to) {
    if (contains(node.id)) {
      final Node? toSwapNode = elementAtOrNull(to);
      if (toSwapNode == null) {
        return false;
      }
      // if them are at the same place,
      // we consider it as they are already
      // swapped
      if (toSwapNode == node) {
        return true;
      }
      bool isLast = toSwapNode.next == null;
      toSwapNode.unlink();
      node
        ..insertBefore(toSwapNode)
        ..unlink();
      isLast
          ? insertNode(node, after: true)
          : elementAt(to).insertAfter(
              node,
            );
      return true;
    }
    return false;
  }

  void adoptChildren(List<Node> nodes, {bool noInvalidation = false}) {
    for (Node node in nodes) {
      insertNode(node, after: true);
    }
  }

  /// Invalidates the current cache of this [Node]
  /// and of its direct parent
  ///
  /// - [willBeAfter]: indicates that the invalidation of the offset will be after this [Node], and not at this one.
  void invalidateDataOffset({bool willBeAfter = false, bool noText = false}) {
    _dataLength = null;
    if (!noText) _text = null;
    if (!willBeAfter) _offset = null;
    if (parent != null) {
      if (isBlockNode) {
        next?.invalidateDataOffset(noText: true);
      }
      if (parent!._dataLength != null || parent!._text != null) {
        parent!.invalidateDataOffset();
      }
    }
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
      invalidatePaths();
    }
  }

  void invalidatePaths() {
    path = -1;
    deepPath = <int>[];
  }

  int get length => _cachedLength ??= children.length;

  Node? get firstChild => children.firstOrNull;
  Node? firstWhere(bool Function(Node) expr) => children.firstWhereOrNull(expr);

  Node? get lastChild => isEmpty ? null : children[length.decr.nonNegative];
  Node? lastWhere(bool Function(Node) expr) => children.lastWhereOrNull(expr);

  Node get first => firstChild!;
  Node get last => lastChild!;

  /// Returns `true` if this node is the first node in the [parent] list.
  bool get isFirst => parent?.firstChild == this;

  /// Returns `true` if this node is the last node in the [parent] list.
  bool get isLast => parent?.lastChild == this;

  bool get isEmpty => length < 1;

  bool get isNotEmpty => !isEmpty;

  int get depthLevel => _deepPath.length - 1;

  Node? queryPath(NodeDepthPath path) {
    Node? node = this;
    assert(path.isNotEmpty, 'path cannot be empty');
    for (int p in path) {
      if (node == null) {
        return null;
      }
      // traverse always getting the child at the path
      // and setting the child as the new node result
      node = node.elementAtOrNull(p);
    }

    return node;
  }

  void insertAfter(Node entry) {
    if (parent == null) {
      throw Exception('Cannot '
          'insert any child after '
          'this since has '
          'no parent relationship');
    }
    // since we insert an element after this
    // the path changes, and we need a new reallocation
    int lastPathKnowed = path;
    isLast
        ? parent!.children.add(entry)
        : parent!.children.insert(lastPathKnowed.next, entry);
    lastPathKnowed++;
    entry
      ..parent = parent
      // to avoid recomputing of a knowed path
      // just set it
      ..path = lastPathKnowed
      ..deepPath = <int>[...parent!.deepPath, lastPathKnowed];
    parent!.invalidateCache(justCache: true);
    if (parent!._cachedLength != null) {
      parent!._cachedLength = parent!._cachedLength! + 1;
    }
    parent!.invalidateDataOffset(willBeAfter: true);
    parent!._fastIndexTreePart[entry.id] = entry;
    if (entry.next != null) {
      // reset the current path of the node
      invalidateCacheOfSiblings(
        node: entry,
        after: true,
        curPath: entry.path,
      );
    }
  }

  void insertBefore(Node entry) {
    if (parent == null) {
      throw Exception('Cannot '
          'insert any child after '
          'this since has '
          'no parent relationship');
    }
    // since we insert an element before this
    // the path changes, and we need a new reallocation
    int lastPathKnowed = path;
    parent!.children.insert(lastPathKnowed, entry);
    entry
      ..parent = parent
      // to avoid recomputing of a knowed path
      // just set it
      ..path = lastPathKnowed
      ..deepPath = <int>[...parent!.deepPath, lastPathKnowed];
    parent!._fastIndexTreePart[entry.id] = entry;
    final int? cachedLength = parent!._cachedLength;
    parent!.invalidateCache(justCache: true);
    if (cachedLength != null) {
      parent!._cachedLength = cachedLength + 1;
    }
    parent!.invalidateDataOffset();
    lastPathKnowed++;
    path = lastPathKnowed;
    deepPath = <int>[
      ...parent!._deepPath,
      lastPathKnowed,
    ];
    if (next != null) {
      invalidateCacheOfSiblings(
        node: this,
        after: true,
        curPath: lastPathKnowed,
      );
    }
  }

  void unlinkIfNeeded() {
    if (isRootOwner) return;
    if (parent == null) return;
    if (parent!.contains(id)) {
      unlink();
    }
  }

  void clearBlock() {
    if (!isBlockNode) return;
    children.clear();
    _fastIndexTreePart.clear();
    invalidateDataOffset(willBeAfter: true);
    invalidateCache(justCache: true);
  }

  void unlink() {
    if (parent != null) {
      parent!.removeNode(this);
      parent = null;
    }
    invalidateCache();
    invalidateDataOffset();
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
    if (isRootOwner) return -1;
    if (!needsComputePath) return _path;

    assert(
        parent != null,
        'to get a path '
        'for child "$id" needs a '
        'parent that wrap it');

    needsComputePath = false;
    int low = 0;
    int high = parent!.length - 1;
    _path = -1;

    while (low <= high) {
      int mid = (low + high) ~/ 2;
      final Node child = parent!.children[mid];
      final int childOffset = child.offset;

      if (childOffset == offset) {
        if (child.id != id) {
          EasyEditorLogger.tree.error(
            'Computing path for $type(id: $id, offset: $_offset) '
            'do a wrong match with a Node that '
            'has the same offset '
            '${child.type}(id: ${child.id}, offset: $childOffset). '
            'Both share the same parent: '
            '${parent!.type}(id: ${parent!.id}, '
            'path: ${parent!.deepPath})',
          );
          break;
        }
        _path = mid;
        break;
      } else if (childOffset < offset) {
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }

    /// Try to make a linear search in case that
    /// binary search does not found the path
    if (_path == _notFoundPath) {
      for (int i = 0; i < parent!.length; i++) {
        if (parent!.children[i].id == id) {
          _path = i;
          break;
        }
      }
    }

    /// This never happen, since, when `needsComputePath`
    /// is `true`, it means that the Node was moved, and requires
    /// a new value to be catched
    if (_path == _notFoundPath) {
      EasyEditorLogger.treeFailures.warn(
        "Not found "
        "child("
        "${id.substring(0, id.length > 5 ? 6 : 4)}) "
        "in parent("
        "${parent!.id.substring(0, parent!.id.length > 5 ? 6 : 4)})",
      );
    }

    return _path;
  }

  set path(int path) {
    _path = path;
    needsComputePath = path < 0;
  }

  set deepPath(NodeDepthPath path) {
    _deepPath = <int>[...path];
    needsComputeFullPath = path.isEmpty;
  }

  /// Get a normalized list of paths where this Node is
  List<int> get deepPath {
    if (!needsComputeFullPath) return _deepPath;
    if (parent == null || !parent!.contains(id)) return <int>[];

    final List<int> path = <int>[];

    jumpToParentExceptRootCaller((Node n) => path.add(n.path));

    _deepPath = <int>[...path.reversed];

    // is not a direct parent
    if (_deepPath.length == 1 && !isBlockNode) {
      EasyEditorLogger.treeFailures.info(
        'Couldn\'t be getted the '
        'correct full deep path of $type(id: $id, offset: $globalStart). '
        'Extra => Most nearest node to the Root: ${jumpToParentExceptRoot()}',
      );
      throw Exception(
        'By some reason, we cannot get the full deep path of $this',
      );
    }

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
      final Map<String, dynamic> newAttributes =
          values["attributes_change"] as Map<String, dynamic>;
      metadata = <String, dynamic>{...metadata, ...newAttributes};
    }
    // here we need to take a look to verify some things
    return this;
  }

  @internal
  void removeCached(Node node) {
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
          .debug("Params for resetting paths: ${<String, Object?>{
        "parent": parent?.id,
        "currentNode": node.id,
        "last_path": curPath,
        "after": after,
      }}");
    }

    isolate.run(
      payload,
      // we prefer just using main thread when the length
      // is less than 130, because is a small amount of nodes
      // to process
      useMainThreadIf: (parent ?? this).length <= 130,
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
