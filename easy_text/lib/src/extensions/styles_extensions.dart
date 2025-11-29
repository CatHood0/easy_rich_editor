import 'package:easy_attribution_text/easy_text.dart';

extension StylesExtension on EasyAttributeStyles {
  // inlines
  BoldAttribute? get bold =>
      attributes[EasyAttribute.bold.key] as BoldAttribute?;
  ItalicAttribute? get italic =>
      attributes[EasyAttribute.italic.key] as ItalicAttribute?;
  UnderlineAttribute? get underline =>
      attributes[EasyAttribute.underline.key] as UnderlineAttribute?;
  StrikeAttribute? get strikethrough =>
      attributes[EasyAttribute.strike.key] as StrikeAttribute?;
  InlineCodeAttribute? get code =>
      attributes[EasyAttribute.code.key] as InlineCodeAttribute?;
  LinkAttribute? get link =>
      attributes[EasyAttribute.link.key] as LinkAttribute?;
  ScriptAttribute? get script =>
      attributes[EasyAttribute.script.key] as ScriptAttribute?;
  ColorAttribute? get color =>
      attributes[EasyAttribute.color.key] as ColorAttribute?;
  BackgroundColorAttribute? get bgColor =>
      attributes[EasyAttribute.bg.key] as BackgroundColorAttribute?;
  FontSizeAttribute? get fontSize =>
      attributes[EasyAttribute.fontSize.key] as FontSizeAttribute?;
  FontFamilyAttribute? get fontFamily =>
      attributes[EasyAttribute.fontFamily.key] as FontFamilyAttribute?;
  // blocks
  AlignmentAttribute? get align =>
      attributes[EasyAttribute.align.key] as AlignmentAttribute?;
  HeaderAttribute? get header =>
      attributes[EasyAttribute.header.key] as HeaderAttribute?;
  ListAttribute? get list =>
      attributes[EasyAttribute.list.key] as ListAttribute?;
  CodeBlockAttribute? get codeblock =>
      attributes[EasyAttribute.codeblock.key] as CodeBlockAttribute?;
  LineheightAttribute? get lineheight =>
      attributes[EasyAttribute.lineHeight.key] as LineheightAttribute?;
  BlockIndentAttribute? get blockIndentation =>
      attributes[EasyAttribute.indentation.key] as BlockIndentAttribute?;
  TextDirectionAttribute? get direction =>
      attributes[EasyAttribute.direction.key] as TextDirectionAttribute?;
  DimensionsAttribute? get dimensions =>
      attributes[EasyAttribute.dimensions.key] as DimensionsAttribute?;
  ListAttribute? get orderedList => list?.isOrdered == true ? list : null;
  ListAttribute? get unOrderedList => list?.isUnordered == true ? list : null;
  ListAttribute? get todoList => list?.isTodo == true ? list : null;
}
