import 'package:easy_text/src/core/attributes/attribute.dart';

class HeaderAttribute extends EasyExclusiveBlockAttribute<int?> {
  HeaderAttribute({required super.value});

  HeaderAttribute.h1() : super(value: 1);
  HeaderAttribute.h2() : super(value: 2);
  HeaderAttribute.h3() : super(value: 3);
  HeaderAttribute.h4() : super(value: 4);
  HeaderAttribute.h5() : super(value: 5);
  HeaderAttribute.h6() : super(value: 6);

  factory HeaderAttribute.fromLevel({
    required int? level,
    bool nullIfUnknown = true,
  }) {
    if (level != null && level > 0 && level < 7) {
      switch (level) {
        case 1:
          return HeaderAttribute.h1();
        case 2:
          return HeaderAttribute.h2();
        case 3:
          return HeaderAttribute.h3();
        case 4:
          return HeaderAttribute.h4();
        case 5:
          return HeaderAttribute.h5();
        case 6:
          return HeaderAttribute.h6();
      }
    }
    return HeaderAttribute(value: nullIfUnknown ? null : level);
  }

  @override
  String get key => 'header';
}
