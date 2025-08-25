import 'package:characters/characters.dart';
import 'package:easy_text/easy_text.dart';
import 'package:easy_text/src/core/easy_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  EasyTextList list = EasyTextList();
  EasyText base() => EasyText.fromStr(
        text: '🎂✨ ¡Today '
            'is a wonderful '
            'day! 🌈🌻',
      );
  EasyText fragment = base();

  setUp(() {
    if (fragment.isLinked) fragment.unlink();
    fragment = base();
    list = EasyTextList()..add(fragment);
  });
  group('take', () {
    test('take first character correctly', () {
      final Characters? taked = fragment.before(1);
      expect(taked, isNotNull);
      expect(taked!.length, equals(1));
      expect(taked.toString(), equals('🎂'));
    });

    test('should take corrupt character', () {
      final String taked = '${fragment.text}'.substring(0, 1);
      expect(
          isSurrogate(
            taked.codeUnitAt(0),
          ),
          isTrue);
    });

    test('take text the correct range before the emoji', () {
      final Characters? taked = fragment.between(25, 31);
      expect(taked, isNotNull);
      expect(taked!.length, equals(6));
      expect(taked.toString(), equals('day! 🌈'));

      final Characters lastChar = taked.characterAt(5);

      expect(lastChar.length, equals(1));
      expect(
          lastChar.toString().length, equals(2)); // Debería tener 2 code units
      expect(isHighSurrogate(lastChar.toString().codeUnitAt(0)), isTrue);
      expect(isLowSurrogate(lastChar.toString().codeUnitAt(1)), isTrue);
    });

    test('should take a bad range before the emoji', () {
      // since first emoji takes two spaces, we need to increase the start
      // and end offsets
      final String taked = fragment.text.toString().substring(26, 32);
      expect(isSurrogate(taked.codeUnitAt(5)), isTrue);
    });

    test('take text the correct range after the emoji', () {
      final Characters? taked = fragment.before(9);
      expect(taked, isNotNull);
      expect(taked!.length, equals(9));
      expect(taked.toString(), equals('🎂✨ ¡Today'));

      final Characters firstChar = taked.characterAt(0);

      expect(firstChar.length, equals(1));
      expect(
          firstChar.toString().length, equals(2)); // Debería tener 2 code units
      expect(isHighSurrogate(firstChar.toString().codeUnitAt(0)), isTrue);
      expect(isLowSurrogate(firstChar.toString().codeUnitAt(1)), isTrue);
    });

    test('should take a bad range after the emoji', () {
      final String taked = '${fragment.text}'.substring(0, 9);
      expect(taked, equals('🎂✨ ¡Toda'));
    });
  });
  group('modifications', () {
    test('add text before emoji', () {
      expect(
          fragment.text.characterAt(0),
          equals(
            '🎂'.characters,
          ));
      fragment.insert(0, 'T');
      // at this point, the current fragment was unlinked
      // since we merged directly with a new node
      expect(fragment.isLinked, isFalse);
      // get that new updated fragment of text
      fragment = list.first;
      expect(fragment.isLinked, isTrue);
      expect(
          fragment.text.characterAt(0),
          equals(
            'T'.characters,
          ));
      expect(
          fragment.text.characterAt(1),
          equals(
            '🎂'.characters,
          ));
    });

    test('add text after emoji', () {
      expect(
          fragment.text.characterAt(1),
          equals(
            '✨'.characters,
          ));
      fragment.insert(2, 'T');
      expect(fragment.isLinked, isTrue);
      expect(
          fragment.text.characterAt(2),
          equals(
            'T'.characters,
          ));
      expect(
          fragment.text.characterAt(1),
          equals(
            '✨'.characters,
          ));
    });

    test('delete entire text', () {
      // when the entire fragment is selected, then
      // we directly remove it
      fragment.delete(0, fragment.length);
      expect(fragment.isLinked, isFalse);
    });

    test('delete emoji', () {
      // when the entire fragment is selected, then
      // we directly remove it
      fragment.delete(0, 1);
      // literally was splitted the selected part
      // so, this fragment was removed
      expect(fragment.isLinked, isFalse);
      expect(
          fragment.text.characterAt(0),
          equals(
            '🎂'.characters,
          ));
      fragment = list.first;
      expect(
          fragment.text.characterAt(0),
          equals(
            '✨'.characters,
          ));
    });
  });

  group('format with correct attributions', () {
    test('format single emoji with bold attribute', () {
      // Format the first emoji (🎂) with bold
      fragment.formatRange(
          0, 1, EasyAttributeStyles.fromAttribute(EasyAttribute.bold));

      // Verify the formatted fragment
      expect(
          fragment.styles.attributes.containsValue(EasyAttribute.bold), isTrue);
      expect(fragment.text.toString(), equals('🎂'));

      // Check that the rest of the text remains unchanged
      final Characters remainingText = list.last.text;
      expect(remainingText.toString(),
          equals('✨ ¡Today is a wonderful day! 🌈🌻'));
    });

    test('format text range that includes emojis with color', () {
      const String color = "#FFFFFF";
      // Format range that includes text and emojis: "✨ ¡Today is"
      fragment.formatRange(
        1,
        11,
        EasyAttributeStyles.fromAttribute(
          EasyAttribute.color.clone(color),
        ),
      );

      // The original fragment should be split into multiple parts
      expect(list.length, greaterThan(1));

      // Find the formatted part
      final EasyText formattedPart = list.firstWhere((EasyText part) =>
          part.styles.attributes.containsKey(EasyAttribute.color.key));
      expect(formattedPart.text.toString(), equals('✨ ¡Today is'));
      expect(
          formattedPart.styles.attributes
              .containsValue(EasyAttribute.color.clone(color)),
          isTrue);
    });

    test('format across multiple EasyText nodes', () {
      // First split the text into multiple parts
      final EasyText? right = fragment.splitAt(5);

      print(right);
      right?.splitAt(10);

      // Format range that spans across multiple nodes
      // ignore: cascade_invocations
      fragment.formatRange(
          3, 8, EasyAttributeStyles.fromAttribute(EasyAttribute.italic));

      // Verify all affected parts have the italic attribute
      final Iterable<EasyText> formattedParts = list.where((EasyText part) =>
          part.styles.attributes.containsValue(EasyAttribute.italic));
      expect(formattedParts.length, greaterThanOrEqualTo(2));
    });

    test('format exclusive attribute (header) replaces other exclusives', () {
      // First apply codeblock attribute
      fragment.formatRange(0, fragment.length,
          EasyAttributeStyles.fromAttribute(EasyAttribute.codeblock));
      expect(fragment.styles.attributes.containsValue(EasyAttribute.codeblock),
          isTrue);

      // Apply header attribute (should replace codeblock)
      fragment.formatRange(0, fragment.length,
          EasyAttributeStyles.fromAttribute(EasyAttribute.h1));
      expect(fragment.styles.attributes.containsValue(EasyAttribute.codeblock),
          isFalse);
      expect(
          fragment.styles.attributes.containsValue(EasyAttribute.h1), isTrue);
    });

    test('format with multiple attributes simultaneously', () {
      final EasyAttributeStyles multipleAttributes =
          EasyAttributeStyles.fromIterable(<EasyAttribute<Object?>>[
        EasyAttribute.bold,
        EasyAttribute.italic,
        EasyAttribute.color,
      ]);

      fragment.formatRange(5, 10, multipleAttributes);

      final EasyText formattedPart = list.firstWhere((EasyText part) =>
          part.styles.attributes.containsValue(EasyAttribute.bold));
      expect(
          formattedPart.styles.attributes.containsValue(EasyAttribute.italic),
          isTrue);
      expect(formattedPart.styles.attributes.containsValue(EasyAttribute.color),
          isTrue);
    });

    test('format empty range does nothing', () {
      final String originalText = fragment.text.toString();
      final EasyAttributeStyles originalAttributes = fragment.styles.copy();

      fragment.formatRange(
          5, 0, EasyAttributeStyles.fromAttribute(EasyAttribute.bold));

      expect(fragment.text.toString(), equals(originalText));
      expect(fragment.styles, equals(originalAttributes));
    });

    test('format range beyond text length formats to end', () {
      fragment.formatRange(
          20, 100, EasyAttributeStyles.fromAttribute(EasyAttribute.underline));

      // Should format from position 20 to the end
      final EasyText formattedPart = list.last;
      expect(
          formattedPart.styles.attributes
              .containsValue(EasyAttribute.underline),
          isTrue);
      expect(formattedPart.text.toString(), equals('day! 🌈🌻'));
    });

    test('format with null styles does nothing', () {
      final String originalText = fragment.text.toString();
      final EasyAttributeStyles originalAttributes = fragment.styles.copy();

      fragment.formatRange(0, 5, null);

      expect(fragment.text.toString(), equals(originalText));
      expect(fragment.styles, equals(originalAttributes));
    });

    test('format then delete preserves attributes in remaining parts', () {
      // First format a range
      fragment.formatRange(
          5, 10, EasyAttributeStyles.fromAttribute(EasyAttribute.bold));

      // Then delete part of the formatted range
      fragment.delete(7, 5);

      // The remaining formatted text should still have the attribute
      final Iterable<EasyText> boldParts = list.where((EasyText part) =>
          part.styles.attributes.containsValue(EasyAttribute.bold));
      expect(boldParts.isNotEmpty, isTrue);
    });

    test('remove formatting from range', () {
      // First apply formatting
      fragment.formatRange(
          0, 10, EasyAttributeStyles.fromAttribute(EasyAttribute.bold));
      expect(list.first.styles.attributes.containsValue(EasyAttribute.bold),
          isTrue);

      // Remove formatting by applying empty styles
      fragment.formatRange(0, 10, EasyAttributeStyles.empty());

      // Should have no attributes
      expect(list.first.styles.attributes.isEmpty, isTrue);
    });
  });
}

bool isSurrogate(int codeUnit) => codeUnit >= 0xD800 && codeUnit <= 0xDFFF;

bool isHighSurrogate(int codeUnit) => codeUnit >= 0xD800 && codeUnit <= 0xDBFF;

bool isLowSurrogate(int codeUnit) => codeUnit >= 0xDC00 && codeUnit <= 0xDFFF;
