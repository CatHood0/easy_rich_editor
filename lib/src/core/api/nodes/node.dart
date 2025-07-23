import 'dart:collection';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:easy_rich_editor/src/logger/editor_logger.dart';
import 'package:easy_rich_editor/src/utils/background_isolate_runner/isolate_runner.dart';
import 'package:easy_rich_editor/src/utils/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_quill_delta_easy_parser/flutter_quill_delta_easy_parser.dart';
import 'package:easy_rich_editor/internal.dart';
import 'package:easy_rich_editor/easy_rich_editor.dart';
import 'package:meta/meta.dart';

final class Node extends LinkedListEntry<Node> {
  String type;
  Node? parent;
  late Map<String, dynamic> metadata = <String, dynamic>{};
  late final Object? value;
  late final String id;

  final LinkedList<Node> children = LinkedList<Node>();
  final GlobalKey<State<StatefulWidget>> key =
      GlobalKey<State<StatefulWidget>>();

  /// A indexed version of this Node Tree Part (N.T.P) that must be always
  /// synced with the elements of the LinkedList, and must share the same
  /// memory reference for any instance (so, we never must put a copy
  /// of an instance here)
  final HashMap<String, Node> _fastIndexTreePart = HashMap();

  @internal
  static String get rootId => 'root';

  /// We cache partially some things while we are processing them
  /// directly at this "box". This is cleaned automatically after
  /// put them into a `NodeChange` class
  @internal
  static String get changeBoxKey => 'changed';

  Node.root({
    String? id,
    List<Node> children = const [],
    Map<String, dynamic>? metadata,
  })  : type = Node.rootId,
        parent = null,
        value = null {
    metadata ??= <String, dynamic>{};
    this.id = id ?? nanoid(8);
    this.metadata = {...metadata};
    adoptChildren(children);
  }

  Node({
    required this.type,
    required this.value,
    this.parent,
    Map<String, dynamic>? metadata,
    String? id,
    bool canModifyChildrenLength = true,
    List<Node> children = const [],
  }) {
    metadata ??= <String, dynamic>{};
    this.id = id ?? nanoid(8);
    this.metadata = {...metadata};
    metadata['can_modify_children_length'] = canModifyChildrenLength;
    adoptChildren(children);
  }

  Node.fromParagraphEmbed({
    String? id,
    this.value,
    this.parent,
    required Paragraph paragraph,
  }) : type = EmbedKeys.key {
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
        value: child.fragments
            .map<Object>(
              (TextFragment e) => e.data,
            )
            .toList(),
        children: [],
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
    this.value,
    this.parent,
    required Paragraph paragraph,
  }) {
    assert(type.trim().isNotEmpty, 'type cannot be empty');
    this.id = id ?? paragraph.id;
    final List<Line> lines = paragraph.unsafeLines();
    for (int i = 0; i < lines.length; i++) {
      final Line line = lines[i];
      final Node lineNode = Node(
        type: ParagraphKeys.lineKey,
        value: <TextFragment>[
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

  Node.text({
    String? id,
    this.type = ParagraphKeys.key,
    this.value,
    this.parent,
    required String text,
  }) {
    assert(type.trim().isNotEmpty, 'type cannot be empty');
    this.id = id ?? nanoid(8);
    if (text.contains(Utils.CR)) {
      final List<String> lines = LineSplitter().convert(text);
      for (int i = 0; i < lines.length; i++) {
        final String line = lines[i];
        final Node lineNode = Node(
          type: ParagraphKeys.lineKey,
          value: <TextFragment>[TextFragment(data: line)],
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
      type: ParagraphKeys.lineKey,
      value: <TextFragment>[TextFragment(data: text)],
      children: <Node>[],
      parent: this,
      canModifyChildrenLength: false,
    );
    insertNode(lineNode);
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

  // TODO: Implement a more efficient search algorithm using previous/next node navigation
  // instead of relying on LinkedList.elementAt() which can lead to O(n²) complexity
  // when used improperly in loops (vs the desired O(n) complexity).
  //
  // Proposed approach:
  // 1. Calculate the relative position of the target node based on its path index
  // 2. Determine search direction based on comparison with current position:
  //    - If target path < current index: search backward (using previous)
  //    - If target path > current index: search forward (using next)
  // 3. Implement bounded search within a calculated proximity area
  //
  // This should maintain O(n) complexity while avoiding elementAt performance penalties
  Node? searchInRange(int index, {bool into = true}) {
    return null;
  }

  Node elementAt(int index) => children.elementAt(index);

  Node? elementAtOrNull(int index) => children.elementAtOrNull(index);

  bool contains(String id) => _fastIndexTreePart[id] != null;

  Node? findById(String id, {bool deep = true}) {
    if (this.id == id) return this;
    if (isEmpty) return null;

    if (contains(id)) {
      return _fastIndexTreePart[id]!;
    }

    if (deep) {
      for (Node child in children) {
        if (child.id == id) return child;
        final Node? node = child.findById(id, deep: deep);
        if (node != null) return node;
      }
    }

    return null;
  }

  Node jumpToParent({bool Function(Node)? stopAt}) {
    if (parent == null || stopAt != null && stopAt(this)) {
      return this;
    }

    return parent!.jumpToParent(stopAt: stopAt);
  }

  int? _cachedLength;

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

  @override
  void insertAfter(Node entry) {
    if (!canAddOrRemovedChildren) return;
    // since we insert an element after this
    // the path changes, and we need a new reallocation
    int lastPathKnowed = _path;
    super.insertAfter(entry);
    entry
      ..parent = parent
      // to avoid recomputing of a knowed path
      // just set it
      ..path = lastPathKnowed++;
    //TODO: implement the same for _deepPath
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
      ..path = lastPathKnowed;
    //TODO: implement the same for _deepPath
    invalidateCache();
    lastPathKnowed++;
    path = lastPathKnowed;
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

  void insertNode(Node child, {int? path, bool after = false}) {
    if (!canAddOrRemovedChildren) return;
    if (child.parent != null && child.parent != this) {
      child.unlink();
    }

    child.parent = this;
    _fastIndexTreePart[child.id] = child;

    if (path == null || path >= length) {
      children.add(child);
      invalidateCache(justCache: true);
      return;
    }

    final Node? entry = children.elementAtOrNull(path);

    if (entry == null) {
      throw Exception("Path($path) was not founded into $type($id)");
    }

    if (after) {
      entry.insertAfter(child);
    } else {
      entry.insertBefore(child);
    }
    invalidateCache(justCache: true);
    // reset the current path of the node
    after ? entry.path = path + 1 : child.path = path + 1;
    invalidateCacheOfSiblings(
      node: after ? entry : child,
      after: true,
      curPath: path + 1,
    );
  }

  void removeNode(Node node) {
    if (!canAddOrRemovedChildren) return;
    assert(
      node.parent == this || contains(node.id),
      "The node passed must be at the same Parent of $id",
    );
    final int path = node.path;
    Node? sibling = node.next;

    node.unlink();
    invalidateCache(justCache: true);

    if (sibling != null) {
      sibling.path = path == 0 ? 0 : path - 1;
      //TODO: apply new index path for deepPath
      invalidateCacheOfSiblings(
        node: sibling,
        after: true,
        curPath: path == 0 ? 0 : path - 1,
      );
    }
  }

  int get depthLevel => _deepPath.length - 1;

  // current path of this node
  int _path = -1;

  // current full path of this node
  List<int> _deepPath = <int>[-1];

  bool needsComputePath = true;
  bool needsComputeFullPath = true;

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

  set path(int path) {
    _path = path;
    needsComputePath = false;
  }

  set deepPath(List<int> path) {
    _deepPath = path;
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

  Map<String, dynamic> getChangedValues() {
    return metadata[Node.changeBoxKey] as Map<String, dynamic>? ?? {};
  }

  void setChangedValues({
    String? textChange,
    Object? value,
    Map<String, dynamic>? attributesChange,
  }) {
    assert(
      metadata[Node.changeBoxKey] == null,
      "calling `setChangedValues` to add "
      "cached changes, must pass always the assert checking. "
      "This can happen when a "
      "change is not processed by the Tree, and it "
      "is cached undefinedly.",
    );

    metadata[Node.changeBoxKey] = {
      "text_change": textChange,
      "value": value,
      "attributes_change": attributesChange,
    };
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

  /// Determines if this Node has a direct value
  ///
  /// You can see this like the following diagram
  ///
  /// ```bash
  /// Line
  ///  └─── Text
  ///
  /// # or
  ///
  /// EmbedLine
  ///  └─── Value
  /// ```
  bool hasDirectValue() {
    return value != null || length == 1 && firstChild!.value != null;
  }

  String dumpTreeStr({
    int tab = 0,
    List<int>? paths,
    bool applyJustIndents = false,
    int applyJustBefore = 0,
    List<int> currentPath = const <int>[],
  }) {
    paths ??= <int>[];

    void writeSubPath(StringBuffer buffer, List<int> paths,
        {bool allowRootIndent = false}) {
      for (int subPath in paths) {
        final int effectiveSubIndent = subPath * 2;
        final String indent = !allowRootIndent
            ? subPath == 0
                ? ""
                : " " * effectiveSubIndent
            : " " * effectiveSubIndent;
        buffer.write(indent);
        if (!applyJustIndents ||
            applyJustIndents && subPath < applyJustBefore) {
          buffer.write("│");
        }
      }
    }

    final Limiter? limiter = Tree.getLimiter(type);
    final StringBuffer buffer = StringBuffer("")
      ..write("$type(${id.substring(0, 4).trim()}-[$path]):");
    if (listEquals(currentPath, deepPath)) {
      buffer.write(" < Cursor position");
    }
    buffer.writeln("");
    final int effectiveIndent = tab * 2;

    if (limiter == null || !limiter.shouldAvoidTraverseInto(this)) {
      for (int i = 0; i < length; i++) {
        final bool isEndChil = i + 1 >= length;
        final bool isNotRootIndent = tab > 0;
        writeSubPath(buffer, paths);
        // adding indenting for the
        if (isNotRootIndent) buffer.write(" " * effectiveIndent);

        final Node child = children.elementAt(i);
        if (isEndChil) {
          // if, is the first child, and the same time
          // the last one, just add an intersection
          //
          // This just add the intersection
          // moves to a new lines and makes the same process
          if (i == 0) {
            buffer.writeln("│");
            writeSubPath(buffer, paths);
            if (isNotRootIndent) buffer.write(" " * effectiveIndent);
          }
          buffer.write("└─");
        } else {
          buffer.write("│");
        }
        // add a separation between the guide lines
        // and the node
        buffer.write(" ");
        buffer.write(
          child.dumpTreeStr(
            tab: tab + 1,
            paths: i + 1 < length ? [...paths, tab] : paths,
            applyJustIndents: i + 1 >= length,
            applyJustBefore: tab,
            currentPath: currentPath,
          ),
        );
      }
    }
    if (value != null) {
      // We need a way to add the other levels knowing
      // if them need a line (parent with more children
      // that the current one, must pass its level)
      writeSubPath(buffer, paths, allowRootIndent: true);
      // we add some extra indentation for the values
      buffer
        ..write(" " * (effectiveIndent + 3))
        ..write("-> ")
        ..writeln(value.toString().replaceAll(RegExp('\n'), '\\n'));
    }
    return buffer.toString();
  }

  Node deepCopy() {
    return Node(
      type: type,
      value: value,
      id: id,
      parent: parent,
      children: [...children],
      metadata: {...metadata},
    );
  }

  @internal
  bool get isRootOwner => id == rootId || type == rootId;

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
