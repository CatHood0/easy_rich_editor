import '../../../../../../attributes.dart';

class LineheightAttribute extends EasyBlockAttribute<double?> {
  const LineheightAttribute([double? height]) : super(value: height);

  /// Corresponds to the value 0.5
  const LineheightAttribute.small() : super(value: 0.5);

  /// Corresponds to the value 1.0
  const LineheightAttribute.normal() : super(value: 1.0);

  /// Corresponds to the value 1.5
  const LineheightAttribute.hight() : super(value: 1.5);

  /// Corresponds to the value 2.0
  const LineheightAttribute.veryHigh() : super(value: 2.0);

  @override
  LineheightAttribute clone(double? value) {
    return LineheightAttribute(value);
  }

  @override
  String get key => 'line-height';
}
