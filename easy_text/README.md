# 📕 Easy Text
A easy and powerful text processing and styling library for Flutter that handles complex Unicode content with ease.

## Overview

`EasyText` provides a easy-to-use solution for working with text in Flutter applications, especially when dealing with complex Unicode characters like emojis, combined glyphs, and multilingual content. It offers precise control over text styling, formatting, and manipulation while handling the intricacies of `UTF-16` encoding transparently thanks of `characters` library implementation.

## Features

### Advanced Unicode Support
- **Grapheme Cluster Awareness**: Handle emojis, combined characters, and complex Unicode sequences as single visual units
- **Safe Text Manipulation**: Insert, delete, and format text without corrupting Unicode sequences
- **Position Accuracy**: Precise cursor positioning and text selection even with complex characters

### Rich Text Styling
- **Inline Attributes**: Apply styles to specific text ranges (bold, italic, color, fonts)
- **Exclusive Formatting**: Smart handling of mutually exclusive styles (headers, code blocks, lists)

## Installation

Add `EasyText` to your `pubspec.yaml`:

```yaml
dependencies:
  easy_attribution_text: <lastes_version> 
```

## Quick Start

Take in account that every `EasyText` instance must be linked/inserted into an `EasyTextList` class. It manages insertion, deletion and positioning of every `EasyText`.

```dart
  // Set every EasyText instance its own parent list
  // to allow search of siblings
  final instance = EasyText.fromStr(text: 'Hello 🎂✨ World 🌈');
  final LinkedList list = EasyTextList.easy(instance);
  assert(instance.isLinked, 'instance must be linked to a list');
```

### Basic Usage

```dart
import 'package:easy_attribution_text/easy_text.dart';

void main() {
  // Create a text element with complex Unicode content
  final text = EasyText.fromStr(text: 'Hello 🎂✨ World 🌈');
  
  // Manipulate text safely
  text.insert(6, 'Beautiful ');
  print(text.str()); // Output: Hello Beautiful 🎂✨ World 🌈
  
  // Apply formatting
  text.formatRange(
     6, 
     9, 
     EasyAttributeStyles.fromAttribute(
       EasyAttribute.bold,
     ),
  );
}
```

### Working with Styles

```dart
// Create styled text
final styledText = EasyText.fromStr(
  'Welcome to EasyText',
  style: EasyAttributeStyles.fromIterable([
    EasyAttribute.bold,
    ColorAttribute('#FFBBAA'),
    FontSizeAttribute(16.0),
  ]),
);

// Format specific ranges
text
  ..formatRange(
    0, 
    5, 
    EasyAttributeStyles.fromAttribute(
      EasyAttribute.italic,
    ),
  )
  ..formatRange(
    11, 
    8, 
    EasyAttributeStyles.fromAttribute(
      EasyAttribute.underline,
    ),
  );
```

### Handling Complex Text

```dart
// Safe manipulation with emojis and Unicode
final complexText = EasyText.fromStr(text: '👨‍👩‍👧‍👦 Family emoji with text');

// These operations won't corrupt the Unicode sequences
complexText.insert(1, ' Beautiful'); // Inserts after the family emoji
complexText.delete(0, 1); // Removes the family emoji correctly
complexText.formatRange(
  0, 
  10, 
  EasyAttributeStyles.fromAttribute(
    EasyAttribute.bold,
  ),
);
```

## Core Concepts

### EasyText parts 
The fundamental building blocks that represent text segments with optional styling. Each part manages its own content and attributes while being part of a larger text structure.

### Attribute System
- **Inline Attributes**: Style applied to text ranges (colors, fonts, decorations)
- **Block Attributes**: Paragraph-level formatting (alignment, indentation, direction)
- **Exclusive Attributes**: Mutually exclusive styles that automatically replace each other 

## Example Usage

### Custom Attributes

```dart
class HighlightAttribute extends EasyAttribute<Color?> {
  const HighlightAttribute([Color? value]) : super(value: value);
  
  @override
  String get key => 'highlight';
  
  @override
  bool get isInline => true;
  
  @override
  bool get exclusive => false;
  
  @override
  bool canMergeWith(EasyAttribute attribute) => true;
  
  @override
  EasyAttribute clone(Color? value) => HighlightAttribute(value);
}

// Register and use custom attribute
EasyAttribute.addCustom({
  'highlight': HighlightAttribute(),
});

text.formatRange(
  0, 
  5, 
  EasyAttributeStyles.fromAttribute(
    HighlightAttribute(Colors.yellow),
  ),
);
```


## Common Use Cases

- **Rich Text Editors**: Full-featured editing with complex styling
- **Chat Applications**: Emoji-heavy text with mixed formatting
- **Content Management Systems**: Structured text with semantic formatting
- **Localization**: Multilingual text with mixed scripts and directions
- **Social Media Apps**: User-generated content with emojis and formatting
