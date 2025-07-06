import 'package:flutter_quill_delta_easy_parser/flutter_quill_delta_easy_parser.dart';

Document get commonDoc => Document(paragraphs: [
      Paragraph.newLine(id: 'new line 1'),
      Paragraph(
        id: 'embed pr 1',
        type: ParagraphType.embed,
        lines: [
          Line.fromData(
            id: 'line of embed pr 1',
            data: {"img": "my/path/to/an/image.jpg"},
          )
        ],
      ),
      Paragraph(
        id: 'normal pr',
        type: ParagraphType.inline,
        lines: [
          Line.fromData(
            id: 'line of normal pr',
            data: "This is just a simple document where we can just ",
          ),
          Line.fromData(
              id: 'line of normal pr (2)',
              data: "use it ",
              attributes: {"underline": true}),
          Line.fromData(
            id: 'line of normal pr (3)',
            data: "to take as an example how work this visualizer. ",
          ),
        ],
      ),
      Paragraph.newLine(id: 'new line 2'),
      Paragraph(
        id: 'block pr',
        type: ParagraphType.block,
        blockAttributes: {"header": 1},
        lines: [
          Line.fromData(
            id: 'line of block pr',
            data: "Examples",
          ),
        ],
      ),
      Paragraph(
        id: 'normal pr 2',
        type: ParagraphType.inline,
        lines: [
          Line.fromData(
            id: 'line of normal pr 2',
            data: "So, since we are just ",
          ),
          Line.fromData(
            id: 'line of normal pr 2-(2)',
            data: "testing",
            attributes: {"underline": true, "bold": true},
          ),
          Line.fromData(
            id: 'line of normal pr 2-(3)',
            data: "to take as an example how work this visualizer. ",
          ),
        ],
      ),
      Paragraph(
        id: 'header pr 2',
        type: ParagraphType.block,
        blockAttributes: {"header": 3},
        lines: [
          Line.fromData(
            id: 'line of header pr 2',
            data: "First example:",
          ),
        ],
      ),
      Paragraph(
        id: 'header sub section pr 1',
        type: ParagraphType.inline,
        lines: [
          Line.fromData(
            id: 'line of header sub section 1',
            data: "When we a visualizer, we should "
                "probably want to select or edit ",
          ),
          Line.fromData(
            id: 'line of header sub section 2',
            data: "any part",
            attributes: {"underline": true, "bold": true},
          ),
          Line.fromData(
            id: 'line of header sub section 3',
            data: " so, why we can try it? ",
          ),
        ],
      ),
      Paragraph(
        id: 'embed pr end',
        type: ParagraphType.embed,
        lines: [
          Line.fromData(
            id: 'embed line pr 2',
            data: {"img": "my/path/to/an/image2.jpg"},
          )
        ],
      ),
      Paragraph.newLine(id: 'new line 3'),
    ]);
