import 'package:collection/collection.dart';
import 'package:easy_attribution_text/easy_text.dart';
import 'package:easy_rich_editor/internal.dart';
import 'package:easy_rich_editor/src/core/api/document/nodes/node.dart';
import 'package:flutter_quill_delta_easy_parser/flutter_quill_delta_easy_parser.dart';
import 'package:meta/meta.dart';
import '../../../../easy_rich_editor.dart';

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
  static const DefaultNodeModifier instance = DefaultNodeModifier();

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
    final VerifyTypeFn verify = supportedTypeValues[type].cast<VerifyTypeFn>();

    return verify(data);
  }

  @override
  Map<String, VerifyTypeFn> get supportedTypeValues => _supportMap;

  /// Inserts data into a node at the specified position.
  ///
  /// Handles various insertion scenarios including:
  /// - Insertion into block nodes and root owners (delegates to appropriate children)
  /// - Embed node creation for non-string data in paragraphs
  /// - Automatic node splitting when inserting incompatible data types
  /// - Parent cache recomputation after successful insertion
  @override
  OperationResult insert(
    Node node,
    int start,
    Object data, {
    EasyText? frag,
    int fragmentPosition = 0,
    int jumpNodeOffset = 0,
    int jumpOffset = 0,
    int stringLimitLength = 300,
    bool computeParentCache = true,
    EasyAttributeStyles? styles,
  }) {
    if (node.isBlockNode || node.isRootOwner) {
      final NodeCursorPosLocation location =
          node.queryPosition(start, inclusive: true);

      if (location.notFoundLocation) {
        return NodeModifier.defaultNonExecutedContext;
      }

      if (node.isBlockNode && location.found && location.node!.isNotBlank) {
        final bool isEmbed = node.isEmbedBlock && node.isNotEmpty;
        if (data is! String && (node.isParagraphBlock || node.isEmbedBlock)) {
          final Node embedBlock = Node.embedBlock(blockAttributes: styles);
          if (location.locationOffset == 0 && location.node!.isFirst) {
            node.insertBefore(embedBlock);
          } else if (location.locationOffset == node.dataLength &&
                  location.node!.isLast ||
              isEmbed) {
            node.insertAfter(embedBlock);
          } else {
            final Node? right = split(
              node,
              start,
              text: location.text,
              linePath: location.node!.path.nonNegative,
              jumpOffset: location.jumpOffset.nonNegative,
              fragmentPath: location.textIndex.nonNegative,
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
              right != null,
              'Node: ${node.shortInfo()} '
              'should be splitted at ${location.locationOffset} '
              'by unsupported type "$data"',
            );
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
              ..value = TextFragment(data: data, attributes: styles?.toJson())
              ..dataLength = 1
              ..text = Node.kObjectReplacementCharacter;
            node.insertAfter(embedBlock);

            assert(node.parent!.contains(embedBlock.id),
                generalAssertNodeInfo(node, embedBlock));

            embedBlock.insertAfter(right!);

            assert(node.parent!.contains(right.id),
                generalAssertNodeInfo(embedBlock, right));

            EasyEditorLogger.tree.debug('Inserting new "$data" in a '
                'new node by an invalid data type for '
                '${node.shortInfo()} founded. '
                'right: ${embedBlock.shortInfo()}, '
                'remaining part after the split: ${right.shortInfo()}');

            final int changeSize = node.dataLength.decr +
                embedBlock.dataLength.decr +
                right.dataLength.decr;

            // we prefer just removing empty nodes directly after split
            if (node.isStrictlyBlank) {
              node.unlink();
            }

            return OperationResult(
              executed: true,
              node: node.parent == null ? embedBlock.parent : node,
              changeSize: changeSize,
            );
          }
          EasyEditorLogger.tree.debug('Inserting new "$data" in a '
              'new node by an invalid data type for '
              '${node.shortInfo()} founded. '
              'right: ${embedBlock.shortInfo()}');

          assert(node.parent!.contains(embedBlock.id),
              generalAssertNodeInfo(node, embedBlock));

          EasyEditorLogger.tree.debug('Moving '
              'start location => '
              'relative to 0 and '
              'global to ${embedBlock.globalStart}');

          return embedBlock.insert(
            0,
            data,
            styles: styles,
            computeParentCache: computeParentCache,
            jumpOffset: 0,
            fragmentPosition: 0,
            stringLimitLength: stringLimitLength,
            jumpNodeOffset: node.endOffset,
          );
        }

        // NOTE: should we implement a way to have more
        // than one embed object per block?
        //
        // Something like this: https://github.com/singerdmx/flutter-quill/issues/2430
        if (data is String && node.isEmbedBlock) {
          final Node block = Node.block(data: "");
          if (location.locationOffset == 0) {
            node.insertBefore(block);
          } else {
            node.insertAfter(block);
          }
          EasyEditorLogger.tree.debug(
            'Inserting new "$data" in a'
            'new node by an invalid data type for '
            '${node.shortInfo()} founded. '
            'New info ${block.shortInfo()}',
          );

          assert(
            node.parent!.contains(block.id),
            '${block.shortInfo()} '
            'should be inserted already '
            'into ${node.shortInfo()} its parent after doing a '
            'insertion, but was not founded. ${node.parent?.shortInfo()}',
          );

          EasyEditorLogger.tree.debug('Moving '
              'start location => '
              'relative to 0 and '
              'global to ${block.globalStart}');

          return block.insert(
            0,
            data,
            styles: styles,
            computeParentCache: computeParentCache,
            jumpOffset: 0,
            fragmentPosition: 0,
            stringLimitLength: stringLimitLength,
            jumpNodeOffset: node.endOffset,
          );
        }
      }

      final OperationResult context = location.node!.insert(
        location.locationOffset,
        data,
        styles: styles,
        frag: location.text,
        jumpNodeOffset: location.jumpNodeOffset,
        fragmentPosition: location.textIndex.or(() => fragmentPosition),
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
        node.hasDefinedValue,
        'value must'
        'be defined');
    assert(
      start >= 0 && start <= node.dataLength.next,
      'start: $start is out of '
      'range => 0 to ${node.dataLength.next}',
    );
    assert(
      // common cases, shouldn't need to throw any assertion
      (data is String || data is! String && !node.isEmbedLine) ||
          // just this specific case should be throwed when required
          data is! String && node.isEmbedLine && node.hasNoEmbed,
      'Cannot insert "$data" in $node since is not empty',
    );

    if (!isSupportedValue(data, node.type)) {
      // when we are into a [Line] or [EmbedLine]
      // we prefer go to parent and trying to make
      // an automatic split
      return node.jumpToParentExceptRoot()!.insert(
            // get the exact start into the block
            jumpNodeOffset.or(() => node.offset, min: 0) + start,
            data,
            styles: styles,
            stringLimitLength: stringLimitLength,
          );
    }

    final OperationResult context = node.insertValueAt(
      data,
      start,
      styles: styles,
      text: frag,
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
  OperationResult delete(
    Node node,
    int start,
    int len, {
    EasyText? text,
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
      // deletes the entire block if the
      // [len] and [start] properties
      // are wrapping it
      //
      // You can see a visual example like:
      //
      // |----------Paragraph---------|
      // | | > Start Cursor pos       |
      // | "This is a simple text"    |
      // | "with different line paths"|
      // | "that we can understand"   |
      // |                        | < End Cursor pos (or if the
      // |                            cursor is after node range)
      // |----------------------------|
      if (node.isBlockNode && node.isSelectingNode(start, len)) {
        node
          ..clearBlock()
          ..unlink();
        return OperationResult(
          executed: true,
          node: node,
          changeSize: len,
        );
      }
      final NodeCursorPosLocation location =
          node.queryPosition(start, inclusive: true);

      if (location.notFoundLocation) {
        return NodeModifier.defaultNonExecutedContext;
      }

      final NodeCursorPosLocation endLocation = end > location.node!.endOffset
          ? node.queryPosition(end, inclusive: true)
          : location;

      if (node.isBlockNode && location.node != endLocation.node!) {
        // both are different
        return location.node!.parent == endLocation.node!.parent
            ? _mergeNodesAtLocations(
                node,
                start,
                len,
                location,
                endLocation,
              )
            : OperationResult.noExecuted();
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
        return OperationResult.noExecuted(NoExecutionReason.invalidEnd);
      }

      final OperationResult context = location.node!.delete(
        location.locationOffset,
        len,
        text: location.text ?? text,
        forward: forward,
        fragmentPosition: location.textIndex.or(() => fragmentPosition),
        jumpNodeOffset: location.jumpNodeOffset.nonNegative,
        jumpOffset: location.jumpOffset.nonNegative,
      );

      if (context.executed &&
          node.isRootOwner &&
          node.changes?[location.node!.id] == null) {
        node
          ..rebuildNodes(changes: <String, int>{
            // if still linked, it was not removed
            // and just was updated internally
            location.node!.id: location.node!.isLinked ? 1 : 0,
          })
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
    // we prefer just removing empty nodes directly before deletion
    if (node.isStrictlyBlankText &&
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
      block
        ..clearBlock()
        ..unlink();
      return OperationResult(
        executed: true,
        changeSize: len,
        node: node,
      );
    }
    final OperationResult context = node.deleteValueAt(
      start,
      len,
      text: text,
      fragmentPath: fragmentPosition.nonNegative,
      jumpedOffset: jumpOffset.nonNegative,
    );
    if (!context.executed) return context;

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

    if (node.isBlank) {
      final Node block = node.jumpToParentExceptRoot()!;
      // we need access to the direct node
      block.jumpToParent()
        ..rebuildNodes(changes: <String, int>{
          block.id: 0,
        })
        ..notify();
      node.unlink();
    }

    return context;
  }

  OperationResult _mergeNodesAtLocations(
    Node node,
    int start,
    int len,
    NodeCursorPosLocation location,
    NodeCursorPosLocation endLocation,
  ) {
    final int startPath = location.node!.path;
    final int endPath = endLocation.node!.path;

    // adjust the len to be more usable for deletion functions
    final int remainingLength =
        (location.node!.dataLength - location.locationOffset).nonNegative;
    final int effectiveRightLen = len - remainingLength;
    final int effectiveLeftLen = len - effectiveRightLen;

    assert(effectiveLeftLen > 0,
        'the len passed does not fit the node ranges. Len $effectiveLeftLen');
    assert(
        effectiveRightLen > 0,
        'the remaining len '
        'for right deletion '
        'does not fit the node ranges. '
        'Len $effectiveRightLen');

    // if wrap all the node, just
    // remove it automatically
    final bool isWrappingEntireStartLocation = location.locationOffset == 0 &&
        effectiveLeftLen == location.node!.dataLength;
    final bool isWrappingEntireEndLocation = endLocation.locationOffset == 0 &&
        effectiveRightLen == endLocation.node!.dataLength;

    final List<Node> betweenNodes = node.subChildren(
      startPath.incr,
      endPath,
    );
    final OperationResult startctx = isWrappingEntireStartLocation
        ? OperationResult(
            executed: true,
            node: location.node,
            changeSize: effectiveLeftLen,
          )
        : location.node!.delete(
            location.locationOffset,
            effectiveLeftLen,
            jumpNodeOffset: location.jumpNodeOffset,
            jumpOffset: location.jumpOffset.nonNegative,
            fragmentPosition: location.textIndex.nonNegative,
            computeParentCache: false,
          );

    assert(
      startctx.executed,
      'the first node deletion was not executed as expected',
    );
    final OperationResult endctx = isWrappingEntireEndLocation
        ? OperationResult(
            executed: true,
            node: endLocation.node,
            changeSize: effectiveRightLen,
          )
        : endLocation.node!.delete(
            0,
            effectiveRightLen,
            text: endLocation.text,
            jumpNodeOffset: endLocation.jumpNodeOffset.nonNegative,
            jumpOffset: endLocation.jumpOffset.nonNegative,
            fragmentPosition: endLocation.textIndex.nonNegative,
            computeParentCache: false,
          );

    assert(
      endctx.executed,
      'the end node deletion wasn\'t executed as expected',
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
    if (isWrappingEntireStartLocation) location.node!.unlink();
    if (isWrappingEntireEndLocation) endLocation.node!.unlink();

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
    //
    // Check if node at the [start]
    // is linked, since it can be removed,
    // so we don't need to make a merge at that case
    if (location.node!.isLinked && endLocation.node!.isLinked) {
      merge(location.node!, endLocation.node!);
    }

    // here is the issue with the bad deepPath update
    for (Node n in betweenNodes) {
      n.unlink();
    }

    if (node.isBlank) {
      node.unlink();
    }

    return MultipleOpResults(
      executed: true,
      changeSize: deletionLength,
      node: node,
      changes: <OperationResult>[startctx, endctx],
    );
  }

  /// Splits a node at the specified position into two separate nodes.
  ///
  /// For embed nodes, returns null since they cannot be split.
  /// For other node types, delegates to the appropriate split method
  /// based on whether the node is a block node or needs parent traversal.
  Node? split(
    Node node,
    int start, {
    int fragmentPath = 0,
    int jumpOffset = 0,
    int linePath = 0,
    int jumpedLineOffset = 0,
    EasyText? text,
  }) {
    if (node.isEmbedBlock || node.isEmbedLine) {
      return null;
    }
    return node.isBlockNode
        ? node.splitLines(
            start,
            text: text,
            fragmentPath: fragmentPath,
            jumpedOffset: jumpOffset,
            linePath: linePath,
            jumpLineOffset: jumpedLineOffset,
          )
        : node.jumpToParent(stopAt: (Node e) => e.isBlockNode).splitLines(
              start,
              text: text,
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
        node.type == other.type && node.isLineBlock,
        'To merge nodes the '
        'type must be equals in both');
    node
      ..texts.addAll(<EasyText>[...other.texts])
      ..text = '${node.nsText.orEmpty}${other.nsText.orEmpty}'.orNull()
      ..dataLength = node.dataLength + other.dataLength;
    assert(node.parent != null, 'node must have a relationship');
    other.unlink();
    if (node.isBlank) {
      node.unlink();
    }
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
  OperationResult format(
    Node node,
    int start,
    int len, {
    required EasyAttributeStyles attributes,
    bool formatBlock = false,
  }) {
    if (node.isBlockNode || node.isRootOwner) {
      final int end = start + len;
      final NodeCursorPosLocation location = node.queryPosition(
        start,
        inclusive: true,
      );

      if (location.notFoundLocation) {
        return OperationResult.noExecuted(NoExecutionReason.invalidStart);
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
          return OperationResult.noExecuted(NoExecutionReason.invalidEnd);
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
      return OperationResult.noExecuted(NoExecutionReason.noSatifyConditions);
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

  OperationResult _formatMultipleNodes(
    Node node,
    NodeCursorPosLocation start,
    NodeCursorPosLocation end,
    int len,
    bool formatBlock,
    EasyAttributeStyles attributes,
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

  OperationResult _formatBlock(
    Node node,
    int start,
    int len,
    EasyAttributeStyles attributes,
  ) {
    return NodeModifier.defaultNonExecutedContext;
  }

  OperationResult _formatCharacters(
    Node node,
    int start,
    int len,
    EasyAttributeStyles attributes,
  ) {
    assert(
        node.hasDefinedValue,
        'node must have '
        'defined value to be used');

    final OperationResult context = node.formatValueAt(
      start,
      len,
      attributes.copy(),
    );

    return context;
  }

  OperationResult _formatCharactersInMultipleNodes(
    Node node,
    int start,
    int end,
    EasyAttributeStyles attributes,
  ) {
    assert(
        node.isBlockNode,
        'node must be '
        'block to format at '
        'specified offset (start and end)');
    return NodeModifier.defaultNonExecutedContext;
  }

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

    final int lineStartOffset = node.offset;
    int lineEndOffset = node.endOffset;
    if (node.isBlockNode) {
      // for block nodes, dataLength has 1 extra pos point
      // so, to validate as the range correctly, we need to
      // decrease that value to its original one
      lineEndOffset = lineEndOffset.prev;
      if (delta.isDeletion &&
          delta.isSelectingEntireRanges(
            lineStartOffset,
            lineEndOffset,
            // even if the range is selecting around this node
            // we need to check it
            strict: false,
          )) {
        // if we are selecting the entire block, just remove it
        node
          ..clearBlock()
          ..unlinkIfNeeded()
          ..invalidateDataOffset();
        return DeltaChangeResult(
          nodeId: node.id,
          removed: true,
          removedEntireNode: true,
          newValidCursorPosition: lineStartOffset,
        );
      }

      // we need to find all the nodes between selection
      if (!delta.isCollapsed) {
        if (delta.isDeletion || delta.isReplace) {
          delete(
            node,
            delta.start,
            delta.len,
            removeEntireNodeWhenEmpty: !delta.isInsertion,
            jumpNodeOffset: lineStartOffset,
            computeParentCache: true,
          );
        }
        if (delta.isInsertion) {
          insert(
            node,
            // limit the start of the offset
            // if required to avoid unexpected behaviors
            // during insertion
            delta.start.limit(node.dataLength.decr.nonNegative),
            delta.inserted!,
            jumpNodeOffset: lineStartOffset,
            computeParentCache: true,
          );
        }
        return DeltaChangeResult(
          nodeId: node.id,
          inserted: delta.isInsertion,
          removed: node.parent == null,
          newValidCursorPosition: lineStartOffset,
        );
      }

      if (delta.isCollapsed) {
        final NodeCursorPosLocation location = node.queryPosition(delta.start);
        if (location.notFoundLocation || location.node == null) {
          return DeltaChangeResult.noExecution();
        }
        return receiveDelta(
          location.node!,
          delta.transformRanges(
            location.locationOffset,
            decrease: true,
          ),
          removedIfRequired: true,
          transformOffsetWhenRequired: transformOffsetWhenRequired,
        );
      }

      return DeltaChangeResult.noExecution();
    }

    assert(
        delta.start >= 0 && delta.end < node.dataLength.next,
        'DeltaNode must have a '
        'valid range to be used into '
        '${node.type}(id: ${node.id}, '
        'global: ${node.globalOffset}, '
        'path: ${node.deepPath})');
    assert(
        // commonly, only nodes that cannot have children
        // are the editable ones
        node.hasDefinedValue && !node.canAddOrRemovedChildren,
        'Only nodes with defined values '
        'can be changed. But, '
        'found: ${node.shortInfo()}');

    // if we are in a situation like the paragraph has no text
    // and the delta received is a deletion, will removed this paragraph
    if (node.isBlankOrEmpty &&
        delta.isCollapsed &&
        delta.isDeletion &&
        delta.isSelectingEntireRanges(
          lineStartOffset,
          lineEndOffset,
        )) {
      node
          .jumpToParent()
          // saves the content that changes
          .rebuildNodes(shouldNotify: true, changes: <String, int>{
        node.jumpToParentExceptRoot()!.id: 0,
      });
      node
        ..unlinkIfNeeded()
        ..invalidateDataOffset()
        ..invalidateCache()
        ..value = null
        ..setDataLength(null, invalidate: false);
      return DeltaChangeResult(
        nodeId: node.id,
        removed: true,
        removedEntireNode: true,
        newValidCursorPosition: lineStartOffset.decr.nonNegative,
      );
    }

    // jump to the most nearest node of the [Root] one
    final Node? block = node.jumpToParentExceptRoot();

    assert(
        block != null,
        'expected parent '
        'relationship in ${node.shortInfo()} '
        'but found nothing');

    if (block!.deepPath.isEmpty) {
      throw IllegalNodeException(
        node: block,
        message: '${block.shortInfo()} has '
            'no parent relationship that '
            'allow tree modifications. Please, '
            'ensure that you have a '
            'root node that contains this block to '
            'allow receiving deltas for nodes',
      );
    }

    if (delta.isDeletion || delta.isReplace) {
      assert(
        delta.len > 0,
        'A DeltaNode cannot '
        'be marked as deletion or replace '
        'if \'len\' property will be '
        'equals or less than zero',
      );
      node.delete(delta.start, delta.len);
    }

    // these methods should also update the internal cache automatically
    if (delta.isInsertion) {
      node.insert(
        delta.start.limit(node.dataLength.decr.nonNegative),
        delta.inserted!,
      );
    }

    if (node.isBlank) {
      EasyEditorLogger.tree.debug(
        'Unlinking '
        '${node.shortInfo()} by empty rule '
        '(when empty it '
        'is removed automatically)',
      );
      node.unlink();
    }

    block.jumpToParent().rebuildNodes(changes: <String, int>{block.id: 1});

    return DeltaChangeResult(
      removed: true,
      executed: true,
      nodeId: node.id,
    );
  }
}
