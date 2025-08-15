import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:easy_rich_editor/src/core/api/document/path/path.dart';
import 'package:easy_rich_editor/src/core/exceptions/illegal_node_exception.dart';
import 'package:easy_rich_editor/src/core/extensions/object_ext.dart';
import 'package:flutter_quill_delta_easy_parser/flutter_quill_delta_easy_parser.dart';

import '../../../easy_rich_editor.dart';
import '../api/document/changes/delta_node.dart';
import '../logger/editor_logger.dart';

abstract class NodeModifier {
  const NodeModifier();
  static const NodeModifier defaultModifier = DefaultNodeModifier();
  Map<String, int> get supportedTypes;
  bool isSupported(String type);

  /// Receives a Delta that contains the change do it to this element
  ///
  /// - [delta]: indicates the change into the Node where this is called. the selection must be normalized
  /// - [removedIfRequired]: indicates if the Node will be removed completely from its parent if the deletion wraps the whole [Node]
  /// - [transformOffsetWhenRequired]: indicates if the [offset] will be modified if requires querying ([queryPosition] method) a [Node]. Tipically, this just happen when we call this method in the Root node.
  ///
  /// All the changes in this [DeltaNode] must be applied just internally into this [Node]
  /// if exceeds the [Node] length, just return [false], indicating that this operation must
  /// be managed by the [Tree] manager
  DeltaChangeResult receiveDelta(
    Node node,
    DeltaNode delta, {
    bool removedIfRequired = false,
    bool transformOffsetWhenRequired = true,
  });
}

/// This modifier calls to both ParagraphNodeModifier and EmbedNodeModifier
class DefaultNodeModifier extends NodeModifier {
  const DefaultNodeModifier();

  @override
  bool isSupported(String type) => supportedTypes[type] == 1;

  @override
  Map<String, int> get supportedTypes => <String, int>{
        ParagraphKeys.key: 1,
        ParagraphKeys.lineKey: 1,
        EmbedKeys.key: 1,
        EmbedKeys.childrenKey: 1,
      };

  @override
  DeltaChangeResult receiveDelta(
    Node node,
    DeltaNode delta, {
    bool removedIfRequired = false,
    bool transformOffsetWhenRequired = true,
  }) {
    if (node.isRootOwner) {
      final NodeCursorPosLocation location = node.queryPosition(delta.start);
      if (location.notFoundLocation || location.node == null) {
        return DeltaChangeResult.noExecution();
      }
      return receiveDelta(
        location.node!,
        delta.transformRanges(
          location.node!.offset,
          decrease: true,
        ),
        removedIfRequired: true,
        transformOffsetWhenRequired: transformOffsetWhenRequired,
      );
    }

    if (!isSupported(node.type)) {
      throw IllegalNodeException(
          node: node,
          message: 'Non supported type detected in $runtimeType. We recommend '
              'using first isSupported method before calling '
              'receiveDelta or any of the other methods');
    }
    assert(
        delta.isNormalized,
        "the delta passed must be "
        "normalized before "
        "making any change");

    final int lineStartOffset = node.offset;
    int lineEndOffset = lineStartOffset + node.dataLength;
    if (node.isBlockNode) {
      // for block nodes, dataLength has 1 extra pos point
      // so, to validate as the range correctly, we need to
      // decrease that value to its original one
      lineEndOffset = lineEndOffset.prev;
      // is removing this node
      if (delta.isDeletion &&
          delta.newLength == 0 &&
          delta.isSelectingEntireRanges(lineStartOffset, lineEndOffset)) {
        if (removedIfRequired) {
          node
            ..clearBlock()
            ..unlinkIfNeeded()
            ..invalidateDataOffset();
          return DeltaChangeResult(
            removed: true,
            newValidCursorPosition: lineStartOffset.decr.nonNegative,
            removedEntireNode: true,
          );
        }

        // we need to find all the nodes between selection
        if (!delta.isCollapsed) {}
      }
      // just search the exact line point
      // to make the modification
      if (delta.isCollapsed) {
        final NodeCursorPosLocation location = node.queryPosition(delta.start);
        if (location.notFoundLocation || location.node == null) {
          return DeltaChangeResult.noExecution();
        }
        return receiveDelta(
          location.node!,
          delta,
          removedIfRequired: true,
          transformOffsetWhenRequired: transformOffsetWhenRequired,
        );
      }

      return DeltaChangeResult.noExecution();
    }

    assert(
        delta.start >= 0 && delta.end <= node.dataLength,
        'DeltaNode must have a '
        'valid range to be used into '
        '${node.type}(id: ${node.id}, '
        'global: ${node.globalOffset}, '
        'path: ${node.deepPath})');
    assert(
        node.hasDefinedValue,
        'Only nodes with defined values '
        'can be changed. But, '
        'found: ${node.shortInfo()}');

    // if we are in a situation like the paragraph has no text
    // and the delta received is a deletion, will removed this paragraph
    if (node.isBlankOrEmpty &&
        delta.isCollapsed &&
        delta.isDeletion &&
        delta.isSelectingEntireRanges(lineStartOffset, lineEndOffset)) {
      node
          .jumpToParent()
          // saves the content that changes
          .rebuildNodes(shouldNotify: true, changes: <String, int>{
        node.jumpToParentExceptRoot()!.id: 1,
      });
      node
        ..unlinkIfNeeded()
        ..invalidateDataOffset()
        ..invalidateCache()
        ..value = <TextFragment>[TextFragment(data: "")]
        ..setDataLength(null, invalidate: false);
      return DeltaChangeResult(
        removed: true,
        removedEntireNode: true,
        newValidCursorPosition: lineStartOffset.decr.nonNegative,
        executed: true,
      );
    }

    // determines the length of the deletion
    final int deltaLength = delta.newLength - delta.oldLength;

    // if we are selecting an entire line, and, we
    // pass a new character, then this will be executed
    //
    // will delete entire content of the line, and pass
    // if required the inserted value
    if (delta.isSelectingEntireRanges(
          lineStartOffset,
          lineEndOffset,
          strict: false,
        ) &&
        deltaLength > 0 &&
        (delta.isReplace || delta.isDeletion)) {
      node
        ..value = <TextFragment>[
          TextFragment(data: delta.isInsertion ? delta.inserted! : "")
        ]
        ..setDataLength(delta.isInsertion ? delta.inserted!.length : 0)
        ..setText("");
      return DeltaChangeResult(
        removed: true,
        newValidCursorPosition: lineStartOffset.decr.nonNegative,
        executed: true,
      );
    }

    // jump to the most nearest node of the [Root] one
    final Node? block = node.jumpToParentExceptRoot();

    if (block == null) {
      throw UnimplementedError(
          "not implemented root cases or non parent cases");
    } else if (block.path == -1) {
      throw IllegalNodeException(node: block, message: "Invalid Parent");
    }

    // these methods should also update the internal cache automatically
    if (delta.isInsertion) {
      // FIXME: we need to have a way to override the stringLimitLength
      node.insert(delta.start, delta.inserted!, stringLimitLength: 300);
    }

    if (!delta.isCollapsed && (delta.isDeletion || (delta.isReplace))) {
      node.delete(
          delta.isInsertion ? delta.start.next : delta.start, delta.end);
    }

    block.jumpToParent().rebuildNodes(changes: <String, int>{block.id: 1});

    return DeltaChangeResult(removed: true, executed: true);
  }
}
