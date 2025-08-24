import 'package:easy_rich_editor/src/core/api/attributes/attribute.dart';

class ItalicAttribute extends EasyAttribute<bool> {
  ItalicAttribute({
    required super.value,
  }) : super(
          key: 'italic',
          isInline: true,
          exclusive: false,
        );
}
