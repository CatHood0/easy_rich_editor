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

Document get largeDoc {
  final List<Paragraph> prs = [];

  for (int i = 0; i <= 10000; i++) {
    prs.addAll([
      Paragraph.newLine(id: 'new line 1 [loop - $i]'),
      Paragraph(
        id: 'embed pr 1 [loop - $i]',
        type: ParagraphType.embed,
        lines: [
          Line.fromData(
            id: 'line of embed pr 1 [loop - $i]',
            data: {"img": "my/path/to/an/image.jpg"},
          )
        ],
      ),
      Paragraph(
        id: 'normal pr [loop - $i]',
        type: ParagraphType.inline,
        lines: [
          Line.fromData(
            id: 'line of normal pr [loop - $i]',
            data: "This is just a simple document where we can just ",
          ),
          Line.fromData(
              id: 'line of normal pr (2) [loop - $i]',
              data: "use it ",
              attributes: {"underline": true}),
          Line.fromData(
            id: 'line of normal pr (3)',
            data: "to take as an example how work this visualizer. ",
          ),
        ],
      ),
      Paragraph.newLine(id: 'new line 2 [loop - $i]'),
      Paragraph(
        id: 'block pr [loop - $i]',
        type: ParagraphType.block,
        blockAttributes: {"header": 1},
        lines: [
          Line.fromData(
            id: 'line of block pr [loop - $i]',
            data: "Examples",
          ),
        ],
      ),
      Paragraph(
        id: 'normal pr 2 [loop - $i]',
        type: ParagraphType.inline,
        lines: [
          Line.fromData(
            id: 'line of normal pr 2 [loop - $i]',
            data: "So, since we are just ",
          ),
          Line.fromData(
            id: 'line of normal pr 2-(2) [loop - $i]',
            data: "testing",
            attributes: {"underline": true, "bold": true},
          ),
          Line.fromData(
            id: 'line of normal pr 2-(3) [loop - $i]',
            data: "to take as an example how work this visualizer. ",
          ),
        ],
      ),
      Paragraph(
        id: 'header pr 2 [loop - $i]',
        type: ParagraphType.block,
        blockAttributes: {"header": 3},
        lines: [
          Line.fromData(
            id: 'line of header pr 2 [loop - $i]',
            data: "First example:",
          ),
        ],
      ),
      Paragraph(
        id: 'header sub section pr 1 [loop - $i]',
        type: ParagraphType.inline,
        lines: [
          Line.fromData(
            id: 'line of header sub section 1 [loop - $i]',
            data: "When we a visualizer, we should "
                "probably want to select or edit ",
          ),
          Line.fromData(
            id: 'line of header sub section 2 [loop - $i]',
            data: "any part",
            attributes: {"underline": true, "bold": true},
          ),
          Line.fromData(
            id: 'line of header sub section 3 [loop - $i]',
            data: " so, why we can try it? ",
          ),
        ],
      ),
      Paragraph(
        id: 'embed pr end [loop - $i]',
        type: ParagraphType.embed,
        lines: [
          Line.fromData(
            id: 'embed line pr 2 [loop - $i]',
            data: {"img": "my/path/to/an/image2.jpg"},
          )
        ],
      ),
      Paragraph.newLine(id: 'new line 3 [loop - $i]'),
    ]);
  }

  return Document(paragraphs: prs);
}
