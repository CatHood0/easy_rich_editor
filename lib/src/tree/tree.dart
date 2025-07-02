import 'dart:collection';

import 'package:flutter_quill_delta_easy_parser_visualizer/src/builders/paragraph/paragraph_keys.dart';
import 'package:flutter_quill_delta_easy_parser_visualizer/src/limiters/limiter_base.dart';
import 'package:flutter_quill_delta_easy_parser_visualizer/src/limiters/paragraph_limiter.dart';
import 'package:flutter_quill_delta_easy_parser_visualizer/src/nodes/node.dart';

import '../builders/header/header_keys.dart';
import '../limiters/header_limiter.dart';

abstract interface class TreeOperations {
  String insertNode(EasyVilNode node);
  String insertNodeAt(EasyVilNode node, {List<int>? path});
  bool moveNodes(List<EasyVilNode> nodes, int to);

  EasyVilNode? query(String rs, {Map<String, dynamic> args = const {}});
  List<EasyVilNode>? queryList(String rs,
      {Map<String, dynamic> args = const {}});
}

class Tree implements TreeOperations {
  final LinkedList<EasyVilNode> nodes = LinkedList<EasyVilNode>();

  /// A simple register with all the limiters.
  ///
  /// Typically, this is used when we need to traverse
  /// to get text info, and we need the specifications
  /// of how works that node type
  static final Map<String, Limiter> _limiters = {
    ParagraphKeys.key: ParagraphLimiter.instance(),
    HeaderKeys.key: HeaderLimiter.instance(),
  };

  static Limiter? getLimiter(String key) {
    return _limiters[key];
  } 

  @override
  EasyVilNode? query(String rs, {Map<String, dynamic> args = const {}}) {
    // TODO: implement query
    throw UnimplementedError();
  }

  @override
  List<EasyVilNode>? queryList(String rs,
      {Map<String, dynamic> args = const {}}) {
    // TODO: implement queryList
    throw UnimplementedError();
  }

  @override
  String insertNode(EasyVilNode node) {
    // TODO: implement insertNode
    throw UnimplementedError();
  }

  @override
  String insertNodeAt(EasyVilNode node, {List<int>? path}) {
    // TODO: implement insertNodeAt
    throw UnimplementedError();
  }

  @override
  bool moveNodes(List<EasyVilNode> nodes, int to) {
    // TODO: implement moveNodes
    throw UnimplementedError();
  }
}
