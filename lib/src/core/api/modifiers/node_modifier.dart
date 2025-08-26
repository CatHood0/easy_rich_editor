import 'package:easy_attribution_text/easy_text.dart';
import 'package:flutter_quill_delta_easy_parser/flutter_quill_delta_easy_parser.dart';
import '../../../../easy_rich_editor.dart';

typedef VerifyTypeFn = bool Function(Object);

abstract class NodeModifier {
  const NodeModifier();
  static const NodeModifier defaultModifier = DefaultNodeModifier();

  static const FragmentChangeContext defaultNonExecutedContext =
      FragmentChangeContext.noExecuted();

  Map<String, int> get supportedTypes;

  /// Determines what types of nodes support values insertion
  ///
  /// Example:
  ///
  /// For [Paragraph] nodes, only we can insert [TextFragment] or [String]
  /// values
  Map<String, VerifyTypeFn> get supportedTypeValues;

  bool isSupported(String type);

  bool isSupportedValue(Object data, String type);

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

  FragmentChangeContext insert(
    Node node,
    int start,
    Object data, {
    Map<String, dynamic>? attributes,
    int jumpNodeOffset = 0,
    int fragmentPosition = 0,
    int jumpOffset = 0,
    bool computeParentCache = true,
    int stringLimitLength = 300,
  });

  /// Format any character or block using the attributes styles
  ///
  /// - [attributes]: the attributes that will be applied
  /// - [start]: the attributes that will be applied
  FragmentChangeContext format(
    Node node,
    int start,
    int len, {
    required EasyAttributeStyles attributes,
    bool formatBlock = false,
  });

  FragmentChangeContext delete(
    Node node,
    int start,
    int len, {
    int jumpOffset = 0,
    bool forward = false,
    int jumpNodeOffset = 0,
    int fragmentPosition = 0,
    int fragmentEndPosition = 0,
    bool computeParentCache = true,
    bool removeEntireNodeWhenEmpty = true,
  });
}
