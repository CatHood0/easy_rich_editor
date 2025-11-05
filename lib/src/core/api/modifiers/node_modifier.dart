import 'package:easy_attribution_text/easy_text.dart';
import 'package:flutter_quill_delta_easy_parser/flutter_quill_delta_easy_parser.dart';
import '../../../../easy_rich_editor.dart';

typedef VerifyTypeFn = bool Function(Object);

abstract class NodeModifier {
  const NodeModifier();

  /// the default node modifier used by methods.
  ///
  /// If [DefaultNodeModifier] does not satisfy our requirements
  /// we can be overrid this property
  static NodeModifier defaultModifier = DefaultNodeModifier();

  static const OperationResult defaultNonExecutedContext =
      OperationResult.noExecuted();

  Map<String, int> get supportedTypes;

  /// Determines what types of nodes support values insertion
  ///
  /// Example:
  ///
  /// For [Paragraph] nodes, only we can insert [EasyText] or [String]
  /// values
  Map<String, VerifyTypeFn> get supportedTypeValues;

  bool isSupported(String type);

  bool isSupportedValue(Object data, String type);

  /// Receives a Delta that contains the change do it to this element
  ///
  /// - [delta]: indicates the change into the Node where this is called. the selection must be normalized
  /// - [removedIfRequired]: indicates if the Node will be removed completely from its parent if the deletion wraps the whole [Node]
  /// - [transformOffsetWhenRequired]: indicates if the [offset] will be modified if requires querying ([queryPosition] method) a [Node]. Tipically, this just happen when we call this method in the Root node.
  DeltaChangeResult receiveDelta(
    Node node,
    DeltaNode delta, {
    bool removedIfRequired = false,
    bool transformOffsetWhenRequired = true,
  });

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
  });

  /// Format any character or block using the attributes styles
  OperationResult format(
    Node node,
    int start,
    int len, {
    required EasyAttributeStyles attributes,
    bool formatBlock = false,
  });

  OperationResult delete(
    Node node,
    int start,
    int len, {
    EasyText? text,
    int jumpOffset = 0,
    bool forward = false,
    int jumpNodeOffset = 0,
    int fragmentPosition = 0,
    int fragmentEndPosition = 0,
    bool computeParentCache = true,
    bool removeEntireNodeWhenEmpty = true,
  });
}
