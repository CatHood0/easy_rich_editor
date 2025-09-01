// ignore_for_file: unnecessary_overrides

import 'package:easy_attribution_text/easy_text.dart';
import 'package:easy_rich_editor/easy_rich_editor.dart';
import 'package:easy_rich_editor/src/core/builders/table/table_keys.dart';

class TableModifier extends DefaultNodeModifier {
  @override
  Map<String, VerifyTypeFn> get supportedTypeValues =>
      super.supportedTypeValues;

  @override
  bool isSupported(String type) {
    return super.isSupported(type);
  }

  @override
  Map<String, int> get supportedTypes => <String, int>{
        TableKeys.key: 1,
        TableKeys.columnKey: 1,
        ...super.supportedTypes,
      };

  @override
  FragmentChangeContext delete(
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
    //TODO: implement multiple columns selection (clean the between columns)
    //TODO: implement full table selection deletion (just clean the columns)
    //TODO: implement block deletion (removes the table if fit 0 to table.dataLength)
    return super.delete(
      node,
      start,
      len,
      text: text,
      forward: forward,
      jumpNodeOffset: jumpNodeOffset,
      fragmentPosition: fragmentPosition,
      fragmentEndPosition: fragmentEndPosition,
      jumpOffset: jumpOffset,
      computeParentCache: computeParentCache,
      removeEntireNodeWhenEmpty: removeEntireNodeWhenEmpty,
    );
  }

  @override
  FragmentChangeContext insert(
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
    //TODO: implement multiple column selection (clean the between columns)
    //TODO: implement full table selection
    //TODO: implement block deletion
    return super.insert(
      node,
      start,
      data,
      frag: frag,
      fragmentPosition: fragmentPosition,
      jumpNodeOffset: jumpNodeOffset,
      jumpOffset: jumpOffset,
      stringLimitLength: stringLimitLength,
      computeParentCache: computeParentCache,
      styles: styles,
    );
  }

  @override
  FragmentChangeContext format(
    Node node,
    int start,
    int len, {
    required EasyAttributeStyles attributes,
    bool formatBlock = false,
  }) {
    //TODO: implement a multiple column selection
    return super.format(
      node,
      start,
      len,
      attributes: attributes,
      formatBlock: formatBlock,
    );
  }

  @override
  DeltaChangeResult receiveDelta(
    Node node,
    DeltaNode delta, {
    bool removedIfRequired = false,
    bool transformOffsetWhenRequired = true,
  }) {
    return super.receiveDelta(
      node,
      delta,
      removedIfRequired: removedIfRequired,
      transformOffsetWhenRequired: transformOffsetWhenRequired,
    );
  }
}
