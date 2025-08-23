import 'package:easy_rich_editor/src/core/api/attributes/attribute.dart';

class UnderlineAttribute extends EasyAttribute<bool> {
  UnderlineAttribute({
    required super.value,
  }) : super(
          key: 'under',
          isInline: true,
          exclusive: false,
        );
}
