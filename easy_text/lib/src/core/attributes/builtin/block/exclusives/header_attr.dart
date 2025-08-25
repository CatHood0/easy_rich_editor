import 'package:easy_text/src/core/attributes/attribute.dart';

class HeaderAttribute extends EasyExclusiveBlockAttribute<int?> {
  const HeaderAttribute([int? value]) : super(value: value);

  const HeaderAttribute.h1() : super(value: 1);
  const HeaderAttribute.h2() : super(value: 2);
  const HeaderAttribute.h3() : super(value: 3);
  const HeaderAttribute.h4() : super(value: 4);
  const HeaderAttribute.h5() : super(value: 5);
  const HeaderAttribute.h6() : super(value: 6);

  @override
  String get key => 'header';

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
    return HeaderAttribute(nullIfUnknown ? null : level);
  }

  @override
  HeaderAttribute clone(int? value) {
    return HeaderAttribute(value);
  }
}
