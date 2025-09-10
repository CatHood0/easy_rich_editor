import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:easy_attribution_text/easy_text.dart';
import 'package:easy_rich_editor/easy_rich_editor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final Node root = ObjectToNodesParser.deltaParse(
    Delta()
      ..insert('This is a single text line\nWhere we expose how works ')
      ..insert(
        'DeltaNode',
        <String, dynamic>{
          'code': true,
          'bold': true,
        },
      )
      ..insert(' in easy_rich_editor package\n'),
  );
  final EasyDocument document = EasyDocument(
    root,
    maxRecordLimit: 300,
  );

  setUp(() {
    expect(root.length, equals(2));
    root.first.receiveDelta(
      DeltaNode.insert(
        insert: '-aaaaaa- ',
        start: 4,
        styles: EasyAttributeStyles.empty(),
      ),
    );
    print(root.first.dumpTreeStr());
  });

  test('test name', () {});
}
