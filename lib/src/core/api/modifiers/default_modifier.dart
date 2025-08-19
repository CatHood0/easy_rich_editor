import 'package:collection/collection.dart';
import 'package:easy_rich_editor/src/core/api/document/nodes/node.dart';
import 'package:easy_rich_editor/src/core/api/document/path/path.dart';
import 'package:easy_rich_editor/src/core/exceptions/illegal_node_exception.dart';
import 'package:easy_rich_editor/src/core/extensions/object_ext.dart';
import 'package:flutter_quill_delta_easy_parser/flutter_quill_delta_easy_parser.dart';
import 'package:meta/meta.dart';

import '../../../../easy_rich_editor.dart';

class DefaultNodeModifier extends NodeModifier {
  const DefaultNodeModifier();

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

  //TODO: implement attributes capabilities
  @override
  FragmentChangeContext insert(
    Node node,
    int start,
    Object data, {
    Map<String, dynamic>? attributes,
    int fragmentPosition = 0,
    int jumpOffset = 0,
    int stringLimitLength = 300,
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
              linePath: location.node!.path,
              jumpOffset: location.jumpOffset,
              fragmentPath: location.fragmentIndex,
              jumpedLineOffset: location.node!.offset,
            );
            computeNewCacheValues(
              location.node!,
              start,
              location.node!.dataLength,
              localStart: location.locationOffset,
              parent: node,
            );
            if (location.node!.isBlankOrEmpty) {
              location.node!.unlink();
            }
            assert(
                right != null && context != null,
                'Node: ${node.shortInfo()} '
                'should be splitted at ${location.locationOffset} '
                'by unsupported type "$data"');
            embedBlock
              ..dataLength = 2
              ..text = Node.kObjectReplacementCharacter;
            if (embedBlock.isEmpty) {
              embedBlock.insertNode(Node.embedChild());
            }
            embedBlock.children[0]
              ..value = <TextFragment>[TextFragment(data: data)]
              ..dataLength = 1
              ..text = Node.kObjectReplacementCharacter;
            if (context != null) {
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

    assert(node.hasDefinedValue, 'value must be defined');
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
            node.offset + start,
            data,
            modifier: this,
          );
    }

    final int lineStartOffset = node.offset;
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
        lineStartOffset + start,
        lineStartOffset + start,
        localStart: start,
        localEnd: start,
        parent: node.parent,
        obj: data,
      );
    }

    // no common, but, can happen when
    // the stringLimitLength is overlapped
    if (context.remainingRanges != null) {
      EasyEditorLogger.tree.debug('The range need to remove '
          'some text between ${context.remainingRanges}');
      // final Node? block = node.jumpToParentExceptRoot();
      // block?.insert(
      //   node.offset + context.remainingRanges!.end,
      //   ,
      // );
      return context;
    }
    return context;
  }

  @override
  FragmentChangeContext delete(
    Node node,
    int start,
    int end, {
    int fragmentPosition = 0,
    int fragmentEndPosition = 0,
    int jumpOffset = 0,
    bool removeEntireNodeWhenEmpty = true,
  }) {
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

        }
      }

      // do a different deletion
      if (node.isRootOwner) {
        if (location.node != endLocation.node) {}
      }

      final FragmentChangeContext context = location.node!.delete(
        location.locationOffset,
        endLocation.locationOffset,
        fragmentPosition: location.fragmentIndex.or(fragmentPosition),
        fragmentEndPosition: endLocation.fragmentIndex,
        jumpOffset: location.jumpOffset.nonNegative,
      );

      if (context.executed && node.isBlockNode) {
        node.jumpToParent()
          ..rebuildNodes(changes: <String, int>{node.id: 1})
          ..notify();
      }
      return context;
    }

    assert(node.hasDefinedValue, 'value must be defined');
    assert(start >= 0 && start <= node.dataLength.next,
        'start: $start is out of range => 0 to ${node.dataLength.next}');
    final int lineOffset = node.offset;
    final FragmentChangeContext context = node.deleteValueAt(
      start,
      end,
      fragmentPath: fragmentPosition,
      jumpedOffset: jumpOffset,
    );
    if (context.executed) {
      EasyEditorLogger.tree.debug('Removing '
          'text between $start '
          'and $end. Execution '
          'ended '
          'sucessfully. '
          'Detailed => $context');
      computeNewCacheValues(
        node,
        start - lineOffset,
        end - lineOffset,
        localStart: start,
        localEnd: end,
        obj: null,
      );
    }

    // no common, but, can happen when
    // the stringLimitLength is overlapped
    if (context.remainingRanges != null) {
      final Node? block = node.jumpToParentExceptRoot();
      EasyEditorLogger.tree.info('The range need to remove '
          'some text between ${context.remainingRanges}');
      block?.delete(
        block.convertToGlobal(context.remainingRanges!.start),
        block.convertToGlobal(context.remainingRanges!.end),
      );
      return context;
    }
    return context;
  }

  @override
  FragmentChangeContext retain(
    Node node,
    Map<String, dynamic> attributes,
    int start, {
    int? end,
    bool passToBlockAttributesIfWrapEntireBlock = false,
  }) {
    // TODO: implement retain
    throw UnimplementedError();
  }

  /// Embeds always return null since they don't need to be splitted
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

  @internal
  void computeNewCacheValues(
    Node node,
    int start,
    int end, {
    Node? parent,
    int? localStart,
    int? localEnd,
    Object? obj,
  }) {
    obj ??= '';
    parent ??= node.parent!;
    final int deleteDelta = end - start;
    int? oldParentLength = parent.nsDataLength != null
        ? parent.nsDataLength!.toInt() - 1
        : parent.nsDataLength;
    int? oldDataLength = node.nsDataLength != null ? 0 : node.nsDataLength;
    String? oldParentText = parent.nsText;
    String? oldText = node.nsText;
    if (oldParentLength != null && oldDataLength != null) {
      node.dataLength = (node.dataLength + obj.length) - deleteDelta;
      parent
        ..invalidateDataOffset(noText: false)
        ..dataLength = (oldParentLength - oldDataLength) + node.nsDataLength!;
    } else {
      node.invalidateDataOffset();
      parent.invalidateDataOffset();
      return;
    }
    if (oldParentText != null) {
      parent.text = oldParentText.replaceRange(
        start,
        end,
        obj.text(),
      );
    }
    if (oldText != null) {
      node.text = oldText.replaceRange(
        localStart ?? start,
        localEnd ?? end,
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
}
