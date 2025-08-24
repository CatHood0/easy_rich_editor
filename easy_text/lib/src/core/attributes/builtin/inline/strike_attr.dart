import 'package:easy_rich_editor/src/core/api/attributes/attribute.dart';

class StrikeAttribute extends EasyAttribute<bool> {
  StrikeAttribute({
    required super.value,
  }) : super(
          key: 'strike',
          isInline: true,
          exclusive: false,
        );
}
