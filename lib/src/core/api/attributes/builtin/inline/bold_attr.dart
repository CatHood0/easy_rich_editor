import 'package:easy_rich_editor/src/core/api/attributes/attribute.dart';

class BoldAttribute extends Attribute<bool> {
  BoldAttribute({
    required super.value,
  }) : super(
          key: 'bold',
          isInline: true,
          exclusive: false,
        );
}
