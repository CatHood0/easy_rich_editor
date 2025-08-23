import 'package:easy_rich_editor/src/core/api/attributes/attribute.dart';

class HeaderAttribute extends EasyAttribute<int?> {
  HeaderAttribute({
    required super.value,
  }) : super(
          key: 'header',
          isInline: false,
          exclusive: true,
        );
}
