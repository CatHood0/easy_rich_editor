import 'package:easy_rich_editor/src/core/api/attributes/attribute.dart';

class UnderlineAttribute extends Attribute<bool> {
  UnderlineAttribute({
    required super.value,
  }) : super(
          key: 'under',
          isInline: true,
        );
}
