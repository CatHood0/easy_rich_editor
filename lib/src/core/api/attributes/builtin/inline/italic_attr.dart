import 'package:easy_rich_editor/src/core/api/attributes/attribute.dart';

class ItalicAttribute extends Attribute<bool> {
  ItalicAttribute({
    required super.value,
  }) : super(
          key: 'italic',
          isInline: true,
          exclusive: false,
        );
}
