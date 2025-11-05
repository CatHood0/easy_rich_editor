import 'dart:convert';
import 'package:easy_rich_editor/easy_rich_editor.dart';

class PlainTextToNodesParser {
  static final LineSplitter _lineSplitter = LineSplitter();
  static Node parse({required String text}) {
    final List<String> lines = _lineSplitter.convert(text);
    final List<Node> nodes = <Node>[];

    for (String line in lines) {
      nodes.add(Node.block(data: line));
    }

    return Node.root(children: <Node>[...nodes]);
  }
}
