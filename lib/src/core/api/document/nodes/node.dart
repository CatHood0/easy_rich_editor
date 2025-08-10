import 'dart:collection';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:easy_rich_editor/src/core/api/document/path/path.dart';
import 'package:easy_rich_editor/src/core/extensions/object_ext.dart';
import 'package:easy_rich_editor/src/core/logger/editor_logger.dart';
import 'package:easy_rich_editor/src/utils/background_isolate_runner/isolate_runner.dart';
import 'package:easy_rich_editor/src/utils/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_quill_delta_easy_parser/flutter_quill_delta_easy_parser.dart';
import 'package:easy_rich_editor/internal.dart';
import 'package:easy_rich_editor/easy_rich_editor.dart';
import 'package:meta/meta.dart';

import '../../../exceptions/illegal_node_exception.dart';
import 'node_iterator.dart';

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

  static const int _notFoundPath = -1;

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
  NodeDepthPath _deepPath = <int>[-1];

  bool needsComputePath = true;
  bool needsComputeFullPath = true;

  Node.root({
    List<Node> children = const [],
    Map<String, dynamic>? metadata,
  })  : type = Node.rootId,
        id = Node.rootId,
        parent = null,
        _value = null {
    metadata ??= <String, dynamic>{};
    this.metadata = {
      ...metadata,
      'root': true,
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
    List<Node> children = const [],
  }) {
    this.value = value;
    this.id = id ?? nanoid(8);
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
    this.parent,
    required Paragraph paragraph,
  }) {
    assert(!paragraph.isEmbed, 'Paragraph cannot be Embed. Found: $paragraph');
    this.id = id ?? paragraph.id;
    _value = null;
    metadata
      ..['block'] = true
      ..['pr_attributes'] = paragraph.blockAttributes;
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
  }

  Node.text({
    String? id,
    this.type = ParagraphKeys.key,
    String lineType = ParagraphKeys.lineKey,
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
          type: lineType,
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
      type: lineType,
      value: <TextFragment>[TextFragment(data: text)],
      children: <Node>[],
      parent: this,
      canModifyChildrenLength: false,
    );
    insertNode(lineNode);
  }

  Object? get value => _value;

  /// Notify to all listeners about the changes in this [Node]
  ///
  /// Use it to force rebuilds if it requires
  void notify() {
    notifyListeners();
  }

  Node? get next => parent == null || path.next >= parent!.length
      ? null
      : parent!.children[path.next];

  Node? get previous =>
      parent == null || path.prev < 0 ? null : parent!.children[path.prev];

  set value(Object? v) {
    // calculate the diff between change to avoid recomputing
    _value = v;
    parent?.invalidateDataOffset();
  }

  int get dataLength {
    // This means that we are into a Parent
    if (isBlockNode) {
      _dataLength ??= children.fold<int>(
        0,
        (int prev, Node n) => prev + n.dataLength,
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

  /// Invalidates the current cache of this [Node]
  /// and of its direct parent
  ///
  /// - [willBeAfter]: indicates that the invalidation of the offset will be after this [Node], and not at this one.
  void invalidateDataOffset({bool willBeAfter = false}) {
    _dataLength = null;
    if (!willBeAfter) _offset = null;
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
    parent?._cachedLength = null;
    if (!justCache) {
      needsComputePath = true;
      needsComputeFullPath = true;
    }
  }

  int get length => _cachedLength ??= children.length;

  Node? get firstChild => children.firstOrNull;
  Node? firstWhere(bool Function(Node) expr) => children.firstWhereOrNull(expr);

  Node? get lastChild => isEmpty ? null : children[length - 1];
  Node? lastWhere(bool Function(Node) expr) => children.lastWhereOrNull(expr);

  Node get first => firstChild!;
  Node get last => lastChild!;

  /// Returns `true` if this node is the first node in the [parent] list.
  bool get isFirst => parent?.first == this;

  /// Returns `true` if this node is the last node in the [parent] list.
  bool get isLast => parent?.last == this;

  bool get isEmpty => length < 1;

  bool get isNotEmpty => !isEmpty;

  int get depthLevel => _deepPath.length - 1;

  /// Simplifies the insertion, it mades the operation directly at the node
  /// passed. The node passed must contain a value
  void insertAtNode(Node line, int offset, Object data, {int? endOffset}) {
    assert(line.value != null, 'node must contain a value to modify it');
  }

  // FIXME: probably we can found a better way to cache the data length
  // instead of invalidating always the parent
  void insertAfter(Node entry) {
    // since we insert an element after this
    // the path changes, and we need a new reallocation
    int lastPathKnowed = path;
    final List<int> effectiveDeepPath = <int>[..._deepPath];
    _deepPath[_deepPath.length - 1] = lastPathKnowed + 1;
    isLast
        ? parent!.children.add(entry)
        : parent!.children.insert(lastPathKnowed + 1, entry);
    entry
      ..parent = parent
      // to avoid recomputing of a knowed path
      // just set it
      ..path = lastPathKnowed++
      ..deepPath = effectiveDeepPath;
    invalidateCache();
    parent!.invalidateDataOffset();
    _fastIndexTreePart[entry.id] = entry;
    if (lastPathKnowed + 1 < length) {
      // reset the current path of the node
      invalidateCacheOfSiblings(
        node: entry,
        after: true,
        curPath: entry.path,
      );
    }
  }

  void insertBefore(Node entry) {
    // since we insert an element before this
    // the path changes, and we need a new reallocation
    int lastPathKnowed = path;
    isLast
        ? parent!.children.add(entry)
        : parent!.children.insert(lastPathKnowed, entry);
    entry
      ..parent = parent
      // to avoid recomputing of a knowed path
      // just set it
      ..path = lastPathKnowed
      ..deepPath = <int>[..._deepPath];
    _fastIndexTreePart[entry.id] = entry;
    invalidateCache();
    parent!.invalidateDataOffset();
    lastPathKnowed++;
    final List<int> effectiveDeepPath = <int>[..._deepPath]
      ..[_deepPath.length - 1] = lastPathKnowed;
    path = lastPathKnowed;
    deepPath = effectiveDeepPath;
    if (next != null) {
      // reset the current path of the node
      invalidateCacheOfSiblings(
        node: this,
        after: true,
        curPath: lastPathKnowed,
      );
    }
  }

  void unlink() {
    assert(
        parent != null,
        'unlink cannot be executed if '
        'there\'s no parent relationship');
    parent!.removeNode(this);
    parent!._removeCached(this);
    parent!.invalidateDataOffset();
    parent = null;
    invalidateCache();
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
    int low = 0;
    int high = parent!.length - 1;
    _path = -1;

    while (low <= high) {
      int mid = (low + high) ~/ 2;
      Node child = parent!.children[mid];

      if (child.globalStart == globalStart) {
        if (child.id != id) {
          break;
        }
        _path = mid;
        break;
      } else if (child.globalStart < globalStart) {
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }

    /// Try to make an linear search in case that
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
      throw Exception(
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
    needsComputePath = false;

    if (_deepPath.isNotEmpty && _deepPath.first != -1) {
      _deepPath[_deepPath.length - 1] = path;
    }
  }

  set deepPath(NodeDepthPath path) {
    _deepPath = <int>[...path];
    needsComputeFullPath = false;
  }

  /// Get a normalized list of paths where this Node is
  List<int> get deepPath {
    if (!needsComputeFullPath) return _deepPath;
    if (parent == null) return <int>[];

    final List<int> path = [this.path];

    Node? curParent = parent!;

    while (curParent != null) {
      // we ignore always the root
      if (curParent.isRootOwner) {
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

/// Represents the granular change do it to a particular [Node]
class DeltaNode {
  // Represents where ends the change
  final int end;
  // Represents where starts the change
  //
  // Must be relative
  final int start;
  final int newLength;
  final int oldLength;
  final Object? inserted;

  DeltaNode({
    required this.oldLength,
    required this.newLength,
    required this.inserted,
    required this.start,
    required this.end,
  });

  /// Returns a Boolean indicating whether the selection is backward.
  bool get isBackward => start < end;

  /// Returns a Boolean indicating whether the selection is forward/normalized.
  bool get isNormalized => start > end;

  /// Returns a Boolean indicating whether the selection start and ends in the same place.
  bool get isCollapsed => start == end;

  bool get isDeletion => inserted == null && (newLength - oldLength) < 0;

  /// Returns a normalized selection that direction is forward.
  DeltaNode get normalized => isBackward
      ? this
      : DeltaNode(
          oldLength: oldLength,
          newLength: newLength,
          inserted: inserted,
          start: end,
          end: start,
        );
}

class DeltaChangeResult {
  final bool removed;
  final bool executed;
  final bool inserted;
  final bool removedEntireNode;

  DeltaChangeResult({
    this.removed = false,
    this.executed = true,
    this.inserted = false,
    this.removedEntireNode = false,
  });

  DeltaChangeResult.noExecution()
      : removed = false,
        executed = false,
        inserted = false,
        removedEntireNode = false;
}
