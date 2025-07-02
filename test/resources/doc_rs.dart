import 'package:flutter_quill_delta_easy_parser/flutter_quill_delta_easy_parser.dart';

Document get commonDoc => Document(paragraphs: [
  Paragraph.newLine(),
  Paragraph(
    id: 'embed pr 1',
    type: ParagraphType.embed,
    lines: [
      Line.fromData(data: {"img": "my/path/to/an/image.jpg"})
    ],
  ),
  Paragraph(
    id: 'normal pr',
    type: ParagraphType.inline,
    lines: [
      Line.fromData(data: "This is just a simple document where we can just "),
      Line.fromData(data: "use it ", attributes: {"underline": true}),
      Line.fromData(data: "to take as an example how work this visualizer. "),
    ],
  ),
  Paragraph.newLine(),
  Paragraph(
    id: 'block pr',
    type: ParagraphType.block,
    blockAttributes: {"header": 1},
    lines: [
      Line.fromData(data: "Examples"),
    ],
  ),
  Paragraph(
    id: 'normal pr 2',
    type: ParagraphType.inline,
    lines: [
      Line.fromData(data: "So, since we are just "),
      Line.fromData(
          data: "testing", attributes: {"underline": true, "bold": true}),
      Line.fromData(data: "to take as an example how work this visualizer. "),
    ],
  ),
  Paragraph(
    id: 'header pr 2',
    type: ParagraphType.block,
    blockAttributes: {"header": 3},
    lines: [
      Line.fromData(data: "First example:"),
    ],
  ),
  Paragraph(
    id: 'header sub section pr 1',
    type: ParagraphType.inline,
    lines: [
      Line.fromData(
          data:
              "When we a visualizer, we should probably want to select or edit "),
      Line.fromData(
          data: "any part", attributes: {"underline": true, "bold": true}),
      Line.fromData(data: " so, why we can try it? "),
    ],
  ),
  Paragraph(
    id: 'embed pr end',
    type: ParagraphType.embed,
    lines: [
      Line.fromData(data: {"img": "my/path/to/an/image2.jpg"})
    ],
  ),
  Paragraph.newLine(),
]);
