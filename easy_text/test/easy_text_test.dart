import 'package:characters/characters.dart';
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

  group('format with correct attributions', () {});
}

bool isSurrogate(int codeUnit) => codeUnit >= 0xD800 && codeUnit <= 0xDFFF;

bool isHighSurrogate(int codeUnit) => codeUnit >= 0xD800 && codeUnit <= 0xDBFF;

bool isLowSurrogate(int codeUnit) => codeUnit >= 0xDC00 && codeUnit <= 0xDFFF;
