import 'package:easy_rich_editor/easy_rich_editor.dart';
import 'package:easy_rich_editor/src/core/api/editor_state/easy_state.dart';
import 'package:flutter_quill_delta_easy_parser/flutter_quill_delta_easy_parser.dart'
    as pr;

Node get randomNode => Node(
      id: EasyTreeState.createNodeId(),
      type: ParagraphKeys.key,
      value: null,
      children: <Node>[],
    );
pr.Document get commonDoc => pr.Document(paragraphs: [
      pr.Paragraph.newLine(id: 'new line 1'),
      pr.Paragraph(
        id: 'embed pr 1',
        type: pr.ParagraphType.embed,
        lines: [
          pr.Line.fromData(
            id: 'line of embed pr 1',
            data: {"img": "my/path/to/an/image.jpg"},
          )
        ],
      ),
      pr.Paragraph(
        id: 'normal pr',
        type: pr.ParagraphType.inline,
        lines: [
          pr.Line.fromData(
            id: 'line of normal pr',
            data: "This is just a simple document where we can just ",
          ),
          pr.Line.fromData(
              id: 'line of normal pr (2)',
              data: "use it ",
              attributes: {"underline": true}),
          pr.Line.fromData(
            id: 'line of normal pr (3)',
            data: "to take as an example how work this visualizer (1). ",
          ),
        ],
      ),
      pr.Paragraph.newLine(id: 'new line 2'),
      pr.Paragraph(
        id: 'block pr',
        type: pr.ParagraphType.block,
        blockAttributes: {"header": 1},
        lines: [
          pr.Line.fromData(
            id: 'line of block pr',
            data: "Examples",
          ),
        ],
      ),
      pr.Paragraph(
        id: 'normal pr 2',
        type: pr.ParagraphType.inline,
        lines: [
          pr.Line.fromData(
            id: 'line of normal pr 2',
            data: "So, since we are just ",
          ),
          pr.Line.fromData(
            id: 'line of normal pr 2-(2)',
            data: "testing",
            attributes: {"underline": true, "bold": true},
          ),
          pr.Line.fromData(
            id: 'line of normal pr 2-(3)',
            data: "to take as an example how work this visualizer (2). ",
          ),
        ],
      ),
      pr.Paragraph(
        id: 'header pr 2',
        type: pr.ParagraphType.block,
        blockAttributes: {"header": 3},
        lines: [
          pr.Line.fromData(
            id: 'line of header pr 2',
            data: "First example:",
          ),
        ],
      ),
      pr.Paragraph(
        id: 'header sub section pr 1',
        type: pr.ParagraphType.inline,
        lines: [
          pr.Line.fromData(
            id: 'line of header sub section 1',
            data: "When we a visualizer, we should "
                "probably want to select or edit ",
          ),
          pr.Line.fromData(
            id: 'line of header sub section 2',
            data: "any part",
            attributes: {"underline": true, "bold": true},
          ),
          pr.Line.fromData(
            id: 'line of header sub section 3',
            data: " so, why we can try it? ",
          ),
        ],
      ),
      pr.Paragraph(
        id: 'embed pr end',
        type: pr.ParagraphType.embed,
        lines: [
          pr.Line.fromData(
            id: 'embed line pr 2',
            data: {"img": "my/path/to/an/image2.jpg"},
          )
        ],
      ),
      pr.Paragraph.newLine(id: 'new line 3'),
    ]);

pr.Document get largeDoc {
  final List<pr.Paragraph> prs = [];

  for (int i = 0; i <= 700; i++) {
    prs.addAll([
      pr.Paragraph.newLine(id: 'new line 1 [loop - $i]'),
      pr.Paragraph(
        id: 'embed pr 1 [loop - $i]',
        type: pr.ParagraphType.embed,
        lines: [
          pr.Line.fromData(
            id: 'line of embed pr 1 [loop - $i]',
            data: {"img": "my/path/to/an/image.jpg"},
          )
        ],
      ),
      pr.Paragraph(
        id: 'normal pr [loop - $i]',
        type: pr.ParagraphType.inline,
        lines: [
          pr.Line.fromData(
            id: 'line of normal pr [loop - $i]',
            data: "This is just a simple document where we can just ",
          ),
          pr.Line.fromData(
              id: 'line of normal pr (2) [loop - $i]',
              data: "use it ",
              attributes: {"underline": true}),
          pr.Line.fromData(
            id: 'line of normal pr (3)',
            data: "to take as an example how work this visualizer. ",
          ),
        ],
      ),
      pr.Paragraph.newLine(id: 'new line 2 [loop - $i]'),
      pr.Paragraph(
        id: 'block pr [loop - $i]',
        type: pr.ParagraphType.block,
        blockAttributes: {"header": 1},
        lines: [
          pr.Line.fromData(
            id: 'line of block pr [loop - $i]',
            data: "Examples",
          ),
        ],
      ),
      pr.Paragraph(
        id: 'normal pr 2 [loop - $i]',
        type: pr.ParagraphType.inline,
        lines: [
          pr.Line.fromData(
            id: 'line of normal pr 2 [loop - $i]',
            data: "So, since we are just ",
          ),
          pr.Line.fromData(
            id: 'line of normal pr 2-(2) [loop - $i]',
            data: "testing",
            attributes: {"underline": true, "bold": true},
          ),
          pr.Line.fromData(
            id: 'line of normal pr 2-(3) [loop - $i]',
            data: "to take as an example how work this visualizer. ",
          ),
        ],
      ),
      pr.Paragraph(
        id: 'header pr 2 [loop - $i]',
        type: pr.ParagraphType.block,
        blockAttributes: {"header": 3},
        lines: [
          pr.Line.fromData(
            id: 'line of header pr 2 [loop - $i]',
            data: "First example:",
          ),
        ],
      ),
      pr.Paragraph(
        id: 'header sub section pr 1 [loop - $i]',
        type: pr.ParagraphType.inline,
        lines: [
          pr.Line.fromData(
            id: 'line of header sub section 1 [loop - $i]',
            data: "When we a visualizer, we should "
                "probably want to select or edit ",
          ),
          pr.Line.fromData(
            id: 'line of header sub section 2 [loop - $i]',
            data: "any part",
            attributes: {"underline": true, "bold": true},
          ),
          pr.Line.fromData(
            id: 'line of header sub section 3 [loop - $i]',
            data: " so, why we can try it? ",
          ),
        ],
      ),
      pr.Paragraph(
        id: 'embed pr end [loop - $i]',
        type: pr.ParagraphType.embed,
        lines: [
          pr.Line.fromData(
            id: 'embed line pr 2 [loop - $i]',
            data: {"img": "my/path/to/an/image2.jpg"},
          )
        ],
      ),
      pr.Paragraph.newLine(id: 'new line 3 [loop - $i]'),
    ]);
  }

  return pr.Document(paragraphs: prs);
}

pr.Document specifyDocLength(int length) {
  final List<pr.Paragraph> prs = [];

  for (int i = 0; i <= length; i++) {
    prs.addAll([
      pr.Paragraph.newLine(id: 'new line 1 [loop - $i]'),
      pr.Paragraph(
        id: 'embed pr 1 [loop - $i]',
        type: pr.ParagraphType.embed,
        lines: [
          pr.Line.fromData(
            id: 'line of embed pr 1 [loop - $i]',
            data: {"img": "my/path/to/an/image.jpg"},
          )
        ],
      ),
      pr.Paragraph(
        id: 'normal pr [loop - $i]',
        type: pr.ParagraphType.inline,
        lines: [
          pr.Line.fromData(
            id: 'line of normal pr [loop - $i]',
            data: "This is just a simple document where we can just ",
          ),
          pr.Line.fromData(
              id: 'line of normal pr (2) [loop - $i]',
              data: "use it ",
              attributes: {"underline": true}),
          pr.Line.fromData(
            id: 'line of normal pr (3)',
            data: "to take as an example how work this visualizer. ",
          ),
        ],
      ),
      pr.Paragraph.newLine(id: 'new line 2 [loop - $i]'),
      pr.Paragraph(
        id: 'block pr [loop - $i]',
        type: pr.ParagraphType.block,
        blockAttributes: {"header": 1},
        lines: [
          pr.Line.fromData(
            id: 'line of block pr [loop - $i]',
            data: "Examples",
          ),
        ],
      ),
      pr.Paragraph(
        id: 'normal pr 2 [loop - $i]',
        type: pr.ParagraphType.inline,
        lines: [
          pr.Line.fromData(
            id: 'line of normal pr 2 [loop - $i]',
            data: "So, since we are just ",
          ),
          pr.Line.fromData(
            id: 'line of normal pr 2-(2) [loop - $i]',
            data: "testing",
            attributes: {"underline": true, "bold": true},
          ),
          pr.Line.fromData(
            id: 'line of normal pr 2-(3) [loop - $i]',
            data: "to take as an example how work this visualizer. ",
          ),
        ],
      ),
      pr.Paragraph(
        id: 'header pr 2 [loop - $i]',
        type: pr.ParagraphType.block,
        blockAttributes: {"header": 3},
        lines: [
          pr.Line.fromData(
            id: 'line of header pr 2 [loop - $i]',
            data: "First example:",
          ),
        ],
      ),
      pr.Paragraph(
        id: 'header sub section pr 1 [loop - $i]',
        type: pr.ParagraphType.inline,
        lines: [
          pr.Line.fromData(
            id: 'line of header sub section 1 [loop - $i]',
            data: "When we a visualizer, we should "
                "probably want to select or edit ",
          ),
          pr.Line.fromData(
            id: 'line of header sub section 2 [loop - $i]',
            data: "any part",
            attributes: {"underline": true, "bold": true},
          ),
          pr.Line.fromData(
            id: 'line of header sub section 3 [loop - $i]',
            data: " so, why we can try it? ",
          ),
        ],
      ),
      pr.Paragraph(
        id: 'embed pr end [loop - $i]',
        type: pr.ParagraphType.embed,
        lines: [
          pr.Line.fromData(
            id: 'embed line pr 2 [loop - $i]',
            data: {"img": "my/path/to/an/image2.jpg"},
          )
        ],
      ),
      pr.Paragraph.newLine(id: 'new line 3 [loop - $i]'),
    ]);
  }
  return pr.Document(paragraphs: prs);
}
