import 'package:characters/characters.dart';
import 'attributes/attribute.dart';

class EasyText {
  final Characters text;
  final Map<String, EasyAttribute> attributes;

  EasyText({
    required this.text,
    required this.attributes,
  });

  EasyText.fromStr({
    required String text,
    required this.attributes,
  }) : text = text.characters;
}
