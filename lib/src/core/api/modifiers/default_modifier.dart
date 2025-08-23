import 'package:collection/collection.dart';
import 'package:easy_rich_editor/src/core/api/attributes/attribute.dart';
import 'package:easy_rich_editor/src/core/api/document/nodes/node.dart';
import 'package:easy_rich_editor/src/core/api/document/path/path.dart';
import 'package:easy_rich_editor/src/core/exceptions/illegal_node_exception.dart';
import 'package:easy_rich_editor/src/core/extensions/object_ext.dart';
import 'package:flutter_quill_delta_easy_parser/flutter_quill_delta_easy_parser.dart';
import 'package:meta/meta.dart';

import '../../../../easy_rich_editor.dart';

//FIXME: we need to use deepCopy method instead of using direct instances
// since context works as a "recorder" of some changes
/// A default implementation of [NodeModifier] that provides standard
/// operations for handling paragraph and embed nodes in a document tree.
///
/// This modifier supports basic text manipulation operations including:
/// - Insertion and deletion of text content
/// - Handling of paragraph and embed node types
/// - Delta application for document changes
/// - Node splitting and merging operations
class DefaultNodeModifier extends NodeModifier {
  const DefaultNodeModifier();

  /// Internal mapping of supported node types to their validation functions.
  static final UnmodifiableMapView<String, VerifyTypeFn> _supportMap =
      UnmodifiableMapView<String, VerifyTypeFn>(<String, VerifyTypeFn>{
    ParagraphKeys.key: (Object data) =>
        data is TextFragment && data.isText || data is String,
    ParagraphKeys.lineKey: (Object data) =>
        data is TextFragment && data.isText || data is String,
    EmbedKeys.key: (Object data) =>
        data is TextFragment && data.isEmbedFragment ||
        data is Map ||
        data is Map<String, dynamic>,
    EmbedKeys.childrenKey: (Object data) =>
        data is TextFragment && data.isEmbedFragment ||
        data is Map ||
        data is Map<String, dynamic>,
  });

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
  bool isSupportedValue(Object data, String type) {
    final VerifyTypeFn? verify =
        supportedTypeValues[type].castOrNull<VerifyTypeFn>();
    if (verify == null) return false;

    return verify(data);
  }

  @override
  Map<String, VerifyTypeFn> get supportedTypeValues => _supportMap;

  /// Applies a delta operation to a node, handling insertions, deletions, and replacements.
  ///
  /// This method processes [DeltaNode] changes and applies them to the target [node].
  /// It handles various scenarios including:
  ///
  /// - Root node operations (delegates to appropriate child nodes)
  /// - Entire node selection and deletion
  /// - Collapsed and non-collapsed delta ranges
  /// - Text fragment modifications
  ///
  /// Params:
  /// - [node]: The target node to apply the delta to
  /// - [delta]: The delta operation containing change information
  /// - [removedIfRequired]: If true, allows node removal when entire content is deleted
  /// - [transformOffsetWhenRequired]: If true, transforms offsets when delegating to child nodes
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
        node.hasDefinedValue && node.isFragmentSupported,
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
      //FIXME: this is invalidating incorrectly
      // we probably can recompute the parent plain text
      // is it's available to be used
      node
        ..value = <TextFragment>[
          TextFragment(data: delta.isInsertion ? delta.inserted! : "")
        ]
        ..invalidateDataOffset()
        ..setDataLength(delta.isInsertion ? delta.inserted!.length : 0)
        ..text = "";
      return DeltaChangeResult(
        removed: true,
        executed: true,
        newValidCursorPosition: lineStartOffset.decr.nonNegative,
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

  /// Inserts data into a node at the specified position.
  ///
  /// Handles various insertion scenarios including:
  /// - Insertion into block nodes and root owners (delegates to appropriate children)
  /// - Embed node creation for non-string data in paragraphs
  /// - Automatic node splitting when inserting incompatible data types
  /// - Parent cache recomputation after successful insertion
  ///
  /// Parameters:
  /// - [node]: The target node for insertion
  /// - [start]: The insertion position within the node
  /// - [data]: The data to insert (String, TextFragment, or Map for embeds)
  /// - [jumpNodeOffset]: Offset adjustment for nested node navigation
  /// - [fragmentPosition]: Specific fragment index for multi-fragment nodes
  /// - [jumpOffset]: Additional offset adjustment
  /// - [stringLimitLength]: Maximum allowed string length for insertion
  /// - [computeParentCache]: Whether to recompute parent cache after insertion
  /// - [attributes]: Optional attributes for the inserted content
  ///
  /// Returns: [FragmentChangeContext] with details about the insertion operation
  ///
  /// Throws: Various assertions for invalid parameters and unsupported operations
  //TODO: implement attributes capabilities
  @override
  FragmentChangeContext insert(
    Node node,
    int start,
    Object data, {
    int jumpNodeOffset = 0,
    int fragmentPosition = 0,
    int jumpOffset = 0,
    int stringLimitLength = 300,
    bool computeParentCache = true,
    Map<String, dynamic>? attributes,
  }) {
    if (node.isBlockNode || node.isRootOwner) {
      final NodeCursorPosLocation location =
          node.queryPosition(start, inclusive: true);
      if (location.notFoundLocation) {
        return NodeModifier.defaultNonExecutedContext;
      }

      if (node.isBlockNode && location.found) {
        final bool isParagraph = node.type == ParagraphKeys.key;
        final bool isEmbed = node.type == EmbedKeys.key &&
            node.isNotEmpty &&
            !location.node!.isValueEmpty;
        if (data is! String && (isParagraph || isEmbed)) {
          final Node embedBlock = Node.embedBlock(data: null);
          if (location.locationOffset == 0 && location.node!.isFirst) {
            node.insertBefore(embedBlock);
          } else if ((location.locationOffset == node.dataLength &&
                  location.node!.isLast) ||
              isEmbed) {
            node.insertAfter(embedBlock);
          } else {
            final (Node? right, MultipleFragmentChangeContext? context) = split(
              node,
              start,
              linePath: location.node!.path.nonNegative,
              jumpOffset: location.jumpOffset.nonNegative,
              fragmentPath: location.fragmentIndex.nonNegative,
              jumpedLineOffset: location.jumpNodeOffset.nonNegative,
            );

            computeNewCacheValues(
              location.node!,
              start,
              location.node!.dataLength,
              localStart: location.locationOffset,
              parent: node,
              computeParentCache: computeParentCache,
            );
            if (location.node!.isBlankOrEmpty) {
              location.node!.unlink();
            }
            assert(
                right != null && context != null,
                'Node: ${node.shortInfo()} '
                'should be splitted at ${location.locationOffset} '
                'by unsupported type "$data"');
            // set automatically the length
            // expected to avoid unnecessary
            // calculations
            embedBlock
              ..dataLength = 2
              ..text = Node.kObjectReplacementCharacter;
            if (embedBlock.isEmpty) {
              embedBlock.insertNode(Node.embedChild());
            }
            // set automatically the values
            // that are already expected
            // to avoid unnecessary calculations
            embedBlock.children[0]
              ..value = <TextFragment>[TextFragment(data: data)]
              ..dataLength = 1
              ..text = Node.kObjectReplacementCharacter;
            if (context != null) {
              // insert in middle of changes
              context.changes.insert(
                1,
                FragmentChangeContext(
                  executed: true,
                  paths: <int>[0],
                  node: embedBlock.first,
                  changeSize: 1,
                ),
              );
            }
            node.insertAfter(embedBlock);

            assert(node.parent!.contains(embedBlock.id),
                generalAssertNodeInfo(node, embedBlock));

            embedBlock.insertAfter(right!);

            assert(node.parent!.contains(right.id),
                generalAssertNodeInfo(embedBlock, right));

            EasyEditorLogger.tree.debug('Inserting new "$data" in a'
                'new node by an invalid data type for '
                '${node.shortInfo()} founded. '
                'right: ${embedBlock.shortInfo()}, '
                'remaining part after the split: ${right.shortInfo()}');

            final int changeSize = node.dataLength.decr +
                embedBlock.dataLength.decr +
                right.dataLength.decr;
            EasyEditorLogger.tree.debug('ChangeInfo('
                'offset: ${node.offset}, '
                'changeSize: $changeSize, '
                'endOffset: ${right.endOffset})');

            // FIXME: we need to implement a better way to
            // return a specific fragment change

            return context?.copyWith(
                  executed: true,
                  changeSize: changeSize,
                  node: node,
                ) ??
                FragmentChangeContext(
                  executed: true,
                  paths: <int>[],
                  node: node,
                  changeSize: changeSize,
                  lastFragmentLength: -1,
                );
          }
          EasyEditorLogger.tree.debug('Inserting new "$data" in a'
              'new node by an invalid data type for '
              '${node.shortInfo()} founded. '
              'New info ${embedBlock.shortInfo()}');

          assert(node.parent!.contains(embedBlock.id),
              generalAssertNodeInfo(node, embedBlock));

          EasyEditorLogger.tree.debug('Moving '
              'start location => '
              'relative to 0 and '
              'global to ${embedBlock.globalStart}');

          return embedBlock.insert(
            0,
            data,
          );
        }

        // By now, [Embeds] can only
        // have one [EmbedLine]
        if (data is String && node.type == EmbedKeys.key) {
          final Node block = Node.block(data: "");
          if (location.locationOffset == 0) {
            node.insertBefore(block);
          } else {
            node.insertAfter(block);
          }
          EasyEditorLogger.tree.debug('Inserting new "$data" in a'
              'new node by an invalid data type for '
              '${node.shortInfo()} founded. '
              'New info ${block.shortInfo()}');

          assert(
              node.parent!.contains(block.id),
              '${block.shortInfo()} '
              'should be inserted already '
              'into ${node.shortInfo()} its parent after doing a '
              'insertion, but was not founded. ${node.parent?.shortInfo()}');

          EasyEditorLogger.tree.debug('Moving '
              'start location => '
              'relative to 0 and '
              'global to ${block.globalStart}');

          return block.insert(
            0,
            data,
          );
        }
      }

      final FragmentChangeContext context = location.node!.insert(
        location.locationOffset,
        data,
        jumpNodeOffset: location.jumpNodeOffset,
        fragmentPosition: location.fragmentIndex.or(fragmentPosition),
        jumpOffset: location.jumpOffset.nonNegative,
        stringLimitLength: stringLimitLength,
      );

      if (context.executed && node.isBlockNode) {
        node.jumpToParent()
          ..rebuildNodes(changes: <String, int>{node.id: 1})
          ..notify();
      }
      return context;
    }

    assert(
        node.hasDefinedValue && node.isFragmentSupported,
        'value must '
        'be defined');
    assert(start >= 0 && start <= node.dataLength.next,
        'start: $start is out of range => 0 to ${node.dataLength.next}');

    if (!isSupportedValue(data, node.type) ||
        // embed nodes can only have a line and fragment per
        // block
        data is! String &&
            node.type == EmbedKeys.childrenKey &&
            !node.isValueEmpty) {
      // when we are into a [Line] or [EmbedLine]
      // we prefer go to parent and trying to make
      // an automatic split
      return node.jumpToParentExceptRoot()!.insert(
            // get the exact start into the block
            jumpNodeOffset.or(node.offset, min: 0) + start,
            data,
            modifier: this,
            stringLimitLength: stringLimitLength,
          );
    }

    final FragmentChangeContext context = node.insertValueAt(
      data,
      start,
      fragmentPath: fragmentPosition,
      jumpedOffset: jumpOffset,
      stringLimitLength: stringLimitLength,
    );

    if (context.executed) {
      EasyEditorLogger.tree.debug('Inserting "$data" was '
          'executed '
          'sucessfully. '
          'Detailed => $context');
      computeNewCacheValues(
        node,
        jumpNodeOffset + start,
        jumpNodeOffset + start,
        localStart: start,
        localEnd: start,
        parent: node.parent,
        obj: data,
        computeParentCache: computeParentCache,
      );
    }

    return context;
  }

  /// Deletes content from a node within the specified range.
  ///
  /// Handles various deletion scenarios including:
  /// - Deletion from block nodes and root owners (delegates to appropriate children)
  /// - Multi-node range deletion (when selection spans multiple nodes)
  /// - Automatic node merging after deletion operations
  /// - Parent cache recomputation after successful deletion
  @override
  FragmentChangeContext delete(
    Node node,
    int start,
    int len, {
    bool forward = false,
    int jumpNodeOffset = 0,
    int fragmentPosition = 0,
    int fragmentEndPosition = 0,
    int jumpOffset = 0,
    bool computeParentCache = true,
    bool removeEntireNodeWhenEmpty = true,
  }) {
    final int end = start + len;
    if (node.isBlockNode || node.isRootOwner) {
      final NodeCursorPosLocation location =
          node.queryPosition(start, inclusive: true);
      final NodeCursorPosLocation endLocation =
          node.queryPosition(end, inclusive: true);

      if (location.notFoundLocation || endLocation.notFoundLocation) {
        return NodeModifier.defaultNonExecutedContext;
      }

      // deletes locally
      if (node.isBlockNode) {
        // both are different
        if (location.node != endLocation.node) {
          _mergeNodesAtLocations(
            node,
            start,
            len,
            location,
            endLocation,
          );
        }
      }

      // this should just pass when we are at the end of a document
      //
      // Something like
      //
      // "This is a simple text"     - first  line
      // "with different line paths" - second line
      // "that we can understand"    - last   line
      //                        | < Start selection here
      //
      // And we try to remove something after
      // the cursor, then this just return a non execution
      // since there's no next element
      if (forward &&
          !location.node!.hasPossibleNextNode &&
          end >= node.dataLength) {
        return FragmentChangeContext.noExecuted(Reason.invalidEnd);
      }

      final FragmentChangeContext context = location.node!.delete(
        location.locationOffset,
        len,
        forward: forward,
        fragmentPosition: location.fragmentIndex.or(fragmentPosition),
        fragmentEndPosition: endLocation.fragmentIndex,
        jumpOffset: location.jumpOffset.nonNegative,
      );

      if (context.executed &&
          node.isRootOwner &&
          node.changes?[location.node!.id] == null) {
        node
          ..rebuildNodes(changes: <String, int>{location.node!.id: 1})
          ..notify();
      }
      return context;
    }

    assert(node.hasDefinedValue, 'value must be defined');
    assert(
        start >= 0 && end <= node.dataLength.next,
        'start: $start, or end: $end are '
        'out of range => 0 to ${node.dataLength.next}. '
        'Node-info: ${node.shortInfo()}');
    if (node.isBlankOrEmpty &&
        // parent has just one line
        node.parent!.length == 1 &&
        // and, if the ends exceeds
        // the length of this node
        // then must be deleted
        end >= node.dataLength) {
      final Node block = node.jumpToParentExceptRoot()!;
      // we need access to the direct node
      block.jumpToParent()
        ..rebuildNodes(changes: <String, int>{
          block.id: 0,
        })
        ..notify();
      block.unlink();
      return FragmentChangeContext(
        executed: true,
        paths: <int>[0],
        changeSize: 1,
        lastFragmentLength: 0,
        node: node,
      );
    }
    final FragmentChangeContext context = node.deleteValueAt(
      start,
      len,
      fragmentPath: fragmentPosition.nonNegative,
      jumpedOffset: jumpOffset.nonNegative,
    );
    if (!context.executed) return context;
    // commonly, we removes entire embeds when are empty
    if (node.isBlankText && node.type == EmbedKeys.childrenKey) {
      node.jumpToParent().overrideChild(
            node.jumpToParentExceptRoot()!.path,
            Node.block(data: ""),
          );
      return context;
    }

    EasyEditorLogger.tree.debug('Removing text '
        'between $start and $end ended '
        'sucessfully. '
        'Detailed => $context');

    computeNewCacheValues(
      node,
      jumpNodeOffset + start,
      jumpNodeOffset + end,
      localStart: start,
      localEnd: end,
      computeParentCache: computeParentCache,
    );

    return context;
  }

  FragmentChangeContext _mergeNodesAtLocations(
    Node node,
    int start,
    int len,
    NodeCursorPosLocation location,
    NodeCursorPosLocation endLocation,
  ) {
    final int startPath = location.node!.path;
    final int endPath = endLocation.node!.path;
    final List<Node> between = node.subChildren(
      startPath.next.limit(node.length),
      // include the last node selected too
      endPath.next.limit(node.length),
    );

    // adjust the len to be more usable for deletion functions
    //
    // commonly, when a len is major than just one node
    // we need to limit it to the exact node length to avoid removing
    // more than the necessary content
    final int effectiveLeftLen = len.limit(location.node!.dataLength);
    final int effectiveRightLen = ((len - effectiveLeftLen))
        .limit(endLocation.node!.dataLength)
        .nonNegative;
    assert(effectiveLeftLen > 0,
        'the len passed does not fit the node ranges. Len $effectiveLeftLen');
    assert(
        effectiveRightLen > 0,
        'the remaining len '
        'for right deletion '
        'does not fit the node ranges. Len $effectiveRightLen');
    final FragmentChangeContext startctx = location.node!.delete(
      location.locationOffset,
      effectiveLeftLen,
      jumpNodeOffset: location.jumpNodeOffset,
      jumpOffset: location.jumpOffset.nonNegative,
      fragmentPosition: location.fragmentIndex.nonNegative,
      computeParentCache: false,
    );
    assert(
      startctx.executed,
      'the first node deletion was not executed as expected',
    );

    endLocation.node!.delete(
      0,
      // we need to get the effective len
      effectiveRightLen,
      jumpNodeOffset: endLocation.jumpNodeOffset,
      jumpOffset: endLocation.jumpOffset.nonNegative,
      fragmentPosition: endLocation.fragmentIndex.nonNegative,
      computeParentCache: false,
    );

    // parent text must be updated here to avoid
    // ambiguous ranges
    int? oldParentLength = node.nsDataLength != null
        ? node.nsDataLength!.toInt() - 1
        : node.nsDataLength;
    String? oldParentText = node.nsText;
    int deletionLength = len;

    if (oldParentLength != null) {
      node
        ..invalidateDataOffset()
        ..dataLength = (oldParentLength - deletionLength).nonNegative;
    }
    if (oldParentText != null) {
      node.text = oldParentText.replaceRange(
        start,
        start + len,
        '',
      );
    }

    // we need to merge both location nodes
    // since, when we are selecting two nodes
    // when we remove text, this means that both
    // will be merged automatically
    //
    // like
    //
    //       | < Start selection here
    // "This is a simple text"
    // "with different line paths"
    // "that we can understand"
    //         | < End selection here
    //
    // After the deletion this should be the result
    //
    // "This can understand"
    merge(location.node!, endLocation.node!);
    for (Node n in between) {
      n.unlink();
    }
    return MultipleFragmentChangeContext(
      executed: true,
      changeSize: deletionLength,
      node: node,
      changes: <FragmentChangeContext>[startctx],
    );
  }

  /// Splits a node at the specified position into two separate nodes.
  ///
  /// For embed nodes, returns null since they cannot be split.
  /// For other node types, delegates to the appropriate split method
  /// based on whether the node is a block node or needs parent traversal.
  (Node?, MultipleFragmentChangeContext?) split(
    Node node,
    int start, {
    int fragmentPath = 0,
    int jumpOffset = 0,
    int linePath = 0,
    int jumpedLineOffset = 0,
  }) {
    if (node.type == EmbedKeys.key || node.type == EmbedKeys.childrenKey) {
      return (null, null);
    }
    return node.isBlockNode
        ? node.splitLines(
            start,
            fragmentPath: fragmentPath,
            jumpedOffset: jumpOffset,
            linePath: linePath,
            jumpLineOffset: jumpedLineOffset,
          )
        : node.jumpToParent(stopAt: (Node e) => e.isBlockNode).splitLines(
              start,
              fragmentPath: fragmentPath,
              jumpedOffset: jumpOffset,
              linePath: linePath,
              jumpLineOffset: jumpedLineOffset,
            );
  }

  /// Merges two nodes of the same type into a single node.
  ///
  /// Combines fragments and text content from both nodes into the first node.
  @internal
  void merge(Node node, Node other) {
    if (node.isBlockNode && other.isBlockNode) {
      assert(
          node.type == other.type,
          'To merge nodes the '
          'type must be equals in both');
      return;
    }
    assert(
      node.type == other.type && node.type == ParagraphKeys.lineKey,
      'To merge nodes the '
      'type must be equals in both',
    );
    final List<TextFragment> leftFragments = node.fragments;
    final List<TextFragment> rightFragments = other.fragments;
    node
      ..nsValue = <TextFragment>[
        ...leftFragments,
        ...rightFragments,
      ]
      ..text = '${node.nsText.orEmpty}${other.nsText.orEmpty}'.orNull()
      ..dataLength = node.dataLength + other.dataLength;
  }

  /// Recomputes cache values for a node and its parent after content changes.
  ///
  /// Updates data length and text content caches to reflect changes made
  /// to the node's content. Handles both local node changes and parent
  /// cache updates.
  @internal
  void computeNewCacheValues(
    Node node,
    int start,
    int end, {
    Node? parent,
    int? localStart,
    int? localEnd,
    Object? obj,
    bool computeParentCache = true,
  }) {
    obj ??= '';
    parent ??= node.parent!;
    localStart ??= start;
    localEnd ??= end;
    final int localDeleteDelta = localEnd - localStart;
    int? oldParentLength = parent.nsDataLength != null
        ? parent.nsDataLength!.toInt() - 1
        : parent.nsDataLength;
    int? oldDataLength = node.nsDataLength;
    String? oldParentText = parent.nsText;
    String? oldText = node.nsText;
    if (oldParentLength != null && oldDataLength != null) {
      node.dataLength = (oldDataLength + obj.length) - localDeleteDelta;
      if (computeParentCache) {
        parent
          ..invalidateDataOffset()
          ..dataLength = (oldParentLength - oldDataLength) + node.dataLength;
      }
    } else {
      node.invalidateDataOffset();
      parent.invalidateDataOffset();
      return;
    }
    if (oldParentText != null && computeParentCache) {
      parent.text = oldParentText.replaceRange(
        start,
        end,
        obj.text(),
      );
    }
    if (oldText != null) {
      node.text = oldText.replaceRange(
        localStart,
        localEnd,
        obj.text(),
      );
    }
  }

  String generalAssertNodeInfo(Node left, Node other) {
    return '${other.shortInfo()} '
        'should be inserted already '
        'after ${left.shortInfo()} => ${left.next?.shortInfo()} | In it\'s parent '
        'after doing an '
        'insertion, but was not founded in ${left.parent?.shortInfo()}'
        '\n'
        '${left.parent?.children.map(
      (Node e) => e.shortInfo(),
    )}';
  }

  @override
  FragmentChangeContext format(
    Node node,
    int start,
    int len, {
    required List<EasyAttribute<dynamic>> attributes,
    bool formatBlock = false,
  }) {
    if (node.isBlockNode || node.isRootOwner) {
      final int end = start + len;
      final NodeCursorPosLocation location = node.queryPosition(
        start,
        inclusive: true,
      );

      if (location.notFoundLocation) {
        return FragmentChangeContext.noExecuted(Reason.invalidStart);
      }

      assert(
          location.node != null,
          'node must be null to allow '
          'formatting operation. Found: $location');

      // if the end exceeds the length of the node at the start location
      if (!node.isBlockNode && len >= location.node!.dataLength) {
        final NodeCursorPosLocation endLocation = node.queryPosition(
          end,
          inclusive: true,
        );
        if (endLocation.notFoundLocation) {
          return FragmentChangeContext.noExecuted(Reason.invalidEnd);
        }

        return _formatMultipleNodes(
          node,
          location,
          endLocation,
          len,
          formatBlock,
          attributes,
        );
      }
      return location.node!.format(
        location.locationOffset,
        len,
        formatBlock: formatBlock,
        attributes: attributes,
      );
    }
    if (formatBlock && !node.isBlockNode) {
      return FragmentChangeContext.noExecuted(Reason.noSatifyConditions);
    }
    assert(
        !formatBlock || formatBlock && node.isBlockNode,
        'formatBlock must '
        'be true to format the '
        'entire node. But, was found: ${node.shortInfo()}');

    return formatBlock
        ? _formatBlock(
            node,
            start,
            len,
            attributes,
          )
        : _formatCharacters(
            node,
            start,
            len,
            attributes,
          );
  }

  FragmentChangeContext _formatMultipleNodes(
    Node node,
    NodeCursorPosLocation start,
    NodeCursorPosLocation end,
    int len,
    bool formatBlock,
    List<EasyAttribute<dynamic>> attributes,
  ) {
    if (!formatBlock && start.node == end.node) {
      return _formatCharactersInMultipleNodes(
        start.node!,
        start.locationOffset,
        end.locationOffset,
        attributes,
      );
    }
    return NodeModifier.defaultNonExecutedContext;
  }

  FragmentChangeContext _formatBlock(
    Node node,
    int start,
    int len,
    List<EasyAttribute<dynamic>> attributes,
  ) {
    return NodeModifier.defaultNonExecutedContext;
  }

  FragmentChangeContext _formatCharacters(
    Node node,
    int start,
    int len,
    List<EasyAttribute<dynamic>> attributes,
  ) {
    assert(
        node.hasDefinedValue && node.isFragmentSupported,
        'node must have '
        'defined value to be used');

    final FragmentChangeContext context = node.formatValueAt(
      start,
      len,
      <EasyAttribute<dynamic>>[...attributes],
    );

    return context;
  }

  FragmentChangeContext _formatCharactersInMultipleNodes(
    Node node,
    int start,
    int end,
    List<EasyAttribute<dynamic>> attributes,
  ) {
    assert(
        node.isBlockNode,
        'node must be '
        'block to format at '
        'specified offset (start and end)');
    return NodeModifier.defaultNonExecutedContext;
  }
}
