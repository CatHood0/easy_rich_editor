import 'package:collection/collection.dart';
import 'package:easy_text/attributes.dart';
import 'package:easy_text/src/core/attributes/builtin/block/alignment_attr.dart';
import 'package:easy_text/src/core/attributes/builtin/block/block_indent_attr.dart';
import 'package:easy_text/src/core/attributes/builtin/block/dimensions_attr.dart';
import 'package:easy_text/src/core/attributes/builtin/block/line_height_attr.dart';
import 'package:easy_text/src/core/attributes/builtin/inline/bg_color_attr.dart';
import 'package:easy_text/src/core/attributes/builtin/inline/color_attr.dart';
import 'package:easy_text/src/core/attributes/builtin/inline/font_size_attr.dart';
import 'package:easy_text/src/core/attributes/builtin/inline/inline_code_attr.dart';
import 'package:easy_text/src/core/attributes/builtin/inline/link_attr.dart';
import 'builtin/block/direction_attr.dart';
import 'builtin/inline/font_family_attr.dart';

part 'abstractions.dart';

/// The base class for all text attributes in the EasyText system.
///
/// [EasyAttribute] represents a styling or formatting property that can be
/// applied to text content. Attributes can be either inline (applied to
/// specific text ranges) or block-level (applied to entire paragraphs or blocks).
///
/// ## Attribute Types:
/// - **Inline Attributes**: Applied to text selections (color, bold, italic, etc.)
/// - **Block Attributes**: Applied to entire paragraphs (alignment, indentation, etc.)
/// - **Exclusive Attributes**: Cannot be combined with other exclusive attributes
///
/// ## Usage Example:
/// ```dart
/// // Create custom attribute
/// class CustomAttr extends EasyAttribute<String> {
///   CustomAttr(String value) : super(value: value);
///
///   @override
///   String get key => 'custom';
///
///   @override
///   bool get isInline => true;
///
///   @override
///   bool get exclusive => false;
///
///   @override
///   bool canMergeWith(EasyAttribute attribute) => true;
///
///   @override
///   EasyAttribute clone(String value) => CustomAttr(value);
/// }
/// ```
abstract class EasyAttribute<T extends Object?> {
  /// The value of this attribute. The type [T] depends on the specific attribute.
  ///
  /// Examples:
  /// - [ColorAttribute]: `Color` value
  /// - [FontSizeAttribute]: `double` value
  /// - [BoldAttribute]: `bool` value (usually `true`)
  final T value;

  /// Creates an [EasyAttribute] with the given [value].
  const EasyAttribute({required this.value});

  /// A unique identifier key for this attribute type.
  ///
  /// This key is used for serialization, deserialization, and attribute lookup.
  /// It must be unique across all attribute types in the system.
  String get key;

  /// Determines whether this attribute is applied inline (to text ranges)
  /// or as a block attribute (to paragraphs/blocks).
  ///
  /// - `true`: Inline attribute (applied to text selections)
  /// - `false`: Block attribute (applied to entire paragraphs)
  bool get isInline;

  /// Determines if this attribute is exclusive and cannot be combined with
  /// other exclusive attributes.
  ///
  /// When `true`, applying this attribute will automatically remove any other
  /// exclusive attributes. For example, you cannot have both a header and a
  /// codeblock attribute on the same text block.
  bool get exclusive;

  /// Determines if this attribute can be merged with another attribute of the
  /// same type or different types.
  ///
  /// Override this method to define custom merge behavior for your attributes.
  ///
  /// Returns `true` if this attribute can coexist with the given [attribute].
  bool canMergeWith(EasyAttribute attribute);

  // ========== STATIC REGISTRY AND ATTRIBUTE MANAGEMENT ==========

  /// Registry for custom attributes added at runtime.
  static final Map<String, EasyAttribute> _customAttributes =
      <String, EasyAttribute<Object?>>{};

  /// Read-only registry of all built-in and custom attributes.
  ///
  /// This registry is used for attribute lookup by key and includes both
  /// built-in attributes and any custom attributes added via [addCustom].
  static final Map<String, EasyAttribute> _registry =
      UnmodifiableMapView<String, EasyAttribute>(
    <String, EasyAttribute<Object?>>{
      ...inlineKeys,
      ...blocks,
    },
  );

  /// Registry of all block-level attributes.
  ///
  /// Block attributes are applied to entire paragraphs or text blocks and
  /// include properties like alignment, indentation, and direction.
  static final Map<String, EasyAttribute> blocks =
      UnmodifiableMapView<String, EasyAttribute>(
    <String, EasyAttribute<Object?>>{
      direction.key: direction,
      align.key: align,
      lineHeight.key: lineHeight,
      indentation.key: indentation,
      dimensions.key: dimensions,
      ...exclusives,
    },
  );

  /// Registry of exclusive attributes that cannot be combined.
  ///
  /// Applying any of these attributes will automatically remove any other
  /// exclusive attributes from the same text range.
  static final Map<String, EasyAttribute> exclusives =
      UnmodifiableMapView<String, EasyAttribute>(
    <String, EasyAttribute<Object?>>{
      header.key: header,
      codeblock.key: codeblock,
      blockquote.key: blockquote,
      list.key: list,
    },
  );

  /// Registry of all inline attributes.
  ///
  /// Inline attributes are applied to specific text ranges and include
  /// properties like bold, italic, color, and font size.
  static final Map<String, EasyAttribute> inlineKeys =
      UnmodifiableMapView<String, EasyAttribute>(
    <String, EasyAttribute<Object?>>{
      italic.key: italic,
      bold.key: bold,
      underline.key: underline,
      strike.key: strike,
      link.key: link,
      code.key: code,
      bg.key: bg,
      fontSize.key: fontSize,
      fontFamily.key: fontFamily,
      color.key: color,
    },
  );

  /// Adds custom attributes to the global attribute registry.
  ///
  /// Use this method to register your custom attributes so they can be
  /// serialized, deserialized, and used throughout the EasyText system.
  ///
  /// ## Example:
  /// ```dart
  /// EasyAttribute.addCustom({
  ///   'highlight': HighlightAttribute(),
  ///   'customStyle': CustomStyleAttribute(),
  /// });
  /// ```
  static void addCustom(Map<String, EasyAttribute> attrs) {
    _customAttributes.addAll(attrs);
  }

  /// Creates an attribute instance from a key-value pair.
  ///
  /// This is primarily used for deserialization and allows creating
  /// attribute instances from stored data.
  ///
  /// Returns `null` if no attribute is found for the given [key].
  ///
  /// ## Example:
  /// ```dart
  /// final attribute = EasyAttribute.fromKeyValue('bold', true);
  /// ```
  static EasyAttribute? fromKeyValue(String key, dynamic value) {
    final EasyAttribute<Object?>? origin =
        _registry[key] ?? _customAttributes[key];
    if (origin == null) return null;
    final EasyAttribute<Object?> attribute = origin.clone(value);
    return attribute;
  }

  // ========== BUILT-IN ATTRIBUTE INSTANCES ==========

  // ---------- INLINE ATTRIBUTES ----------

  /// Italic text formatting attribute.
  static const ItalicAttribute italic = ItalicAttribute();

  /// Bold text formatting attribute.
  static const BoldAttribute bold = BoldAttribute();

  /// Underline text formatting attribute.
  static const UnderlineAttribute underline = UnderlineAttribute();

  /// Strikethrough text formatting attribute.
  static const StrikeAttribute strike = StrikeAttribute();

  /// Hyperlink attribute for making text clickable.
  static const LinkAttribute link = LinkAttribute();

  /// Inline code formatting attribute (monospace with background).
  static const InlineCodeAttribute code = InlineCodeAttribute();

  /// Background color attribute for text.
  static const BackgroundColorAttribute bg = BackgroundColorAttribute();

  /// Text color attribute.
  static const ColorAttribute color = ColorAttribute();

  /// Font size attribute.
  static const FontSizeAttribute fontSize = FontSizeAttribute();

  /// Font family attribute.
  static const FontFamilyAttribute fontFamily = FontFamilyAttribute();

  // ---------- BLOCK ATTRIBUTES ----------

  /// Text alignment attribute (default alignment).
  static const AlignmentAttribute align = AlignmentAttribute();

  /// Left text alignment attribute.
  static const AlignmentAttribute leftAlign = AlignmentAttribute.left();

  /// Right text alignment attribute.
  static const AlignmentAttribute rightAlign = AlignmentAttribute.right();

  /// Center text alignment attribute.
  static const AlignmentAttribute centerAlign = AlignmentAttribute.center();

  /// Block indentation attribute.
  static const BlockIndentAttribute indentation = BlockIndentAttribute();

  /// Dimensions attribute for controlling width/height of text blocks.
  static const DimensionsAttribute dimensions = DimensionsAttribute();

  /// Text direction attribute (default direction).
  static const TextDirectionAttribute direction = TextDirectionAttribute();

  /// Left-to-right text direction attribute.
  static const TextDirectionAttribute ltr = TextDirectionAttribute.ltr();

  /// Right-to-left text direction attribute.
  static const TextDirectionAttribute rtl = TextDirectionAttribute.rtl();

  /// Line height attribute (default height).
  static const LineheightAttribute lineHeight = LineheightAttribute();

  /// Small line height attribute.
  static const LineheightAttribute lineHeightSmall =
      LineheightAttribute.small();

  /// Normal line height attribute.
  static const LineheightAttribute lineHeightNormal =
      LineheightAttribute.normal();

  /// High line height attribute.
  static const LineheightAttribute lineHeightHigh = LineheightAttribute.hight();

  /// Very high line height attribute.
  static const LineheightAttribute lineHeightVeryHigh =
      LineheightAttribute.veryHigh();

  // ---------- EXCLUSIVE ATTRIBUTES ----------

  /// Header attribute (default level).
  static const HeaderAttribute header = HeaderAttribute();

  /// Header level 1 attribute.
  static const HeaderAttribute h1 = HeaderAttribute.h1();

  /// Header level 2 attribute.
  static const HeaderAttribute h2 = HeaderAttribute.h2();

  /// Header level 3 attribute.
  static const HeaderAttribute h3 = HeaderAttribute.h3();

  /// Header level 4 attribute.
  static const HeaderAttribute h4 = HeaderAttribute.h4();

  /// Header level 5 attribute.
  static const HeaderAttribute h5 = HeaderAttribute.h5();

  /// Header level 6 attribute.
  static const HeaderAttribute h6 = HeaderAttribute.h6();

  /// List attribute (default type).
  static const ListAttribute list = ListAttribute();

  /// Unordered list attribute (bullet points).
  static const ListAttribute ul = ListAttribute.unordered();

  /// Ordered list attribute (numbered).
  static const ListAttribute ol = ListAttribute.ordered();

  /// Todo list attribute (checkboxes).
  static const ListAttribute todo = ListAttribute.todo();

  /// Code block attribute (active state).
  static final CodeBlockAttribute codeblock = CodeBlockAttribute.active();

  /// Blockquote attribute for quoted text.
  static const BlockquoteAttribute blockquote = BlockquoteAttribute();

  /// Creates a new instance of this attribute with the given [value].
  ///
  /// This method must be implemented by all subclasses to support
  /// cloning and deserialization.
  EasyAttribute clone(T value);

  @override
  bool operator ==(covariant EasyAttribute<T> other) {
    if (identical(this, other)) return true;
    return key == other.key && value == other.value;
  }

  @override
  int get hashCode => value.hashCode;
}
