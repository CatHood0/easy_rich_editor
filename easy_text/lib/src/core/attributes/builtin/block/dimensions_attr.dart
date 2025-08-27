import '../../../../../attributes.dart';

class DimensionsAttribute extends EasyBlockAttribute<Map<String, dynamic>?> {
  const DimensionsAttribute([Map<String, dynamic>? value])
      : super(value: value);

  DimensionsAttribute.width([int? width])
      : super(value: <String, dynamic>{
          'width': width,
        });
  DimensionsAttribute.height([int? height])
      : super(value: <String, dynamic>{
          'height': height,
        });
  DimensionsAttribute.both([int? width, int? height])
      : super(value: <String, dynamic>{
          'width': width,
          'height': height,
        });

  @override
  DimensionsAttribute clone(Map<String, dynamic>? value) {
    return DimensionsAttribute(value);
  }

  @override
  String get key => 'block-dimensions';
}
