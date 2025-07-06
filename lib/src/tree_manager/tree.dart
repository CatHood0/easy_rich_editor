import 'dart:collection';

import 'package:flutter/material.dart' show TextRange, TextSelection;
import 'package:easy_rich_editor/easy_rich_editor.dart';
import 'package:meta/meta.dart';

import '../../internal.dart';

@internal
class Tree implements TreeOperations {
  final LinkedList<Node> nodes = LinkedList<Node>();

  /// A simple register with all the limiters.
  ///
  /// Typically, this is used when we need to traverse
  /// to get text info, and we need the specifications
  /// of how works that node type
  static final Map<String, Limiter> _limiters = {
    ParagraphKeys.key: ParagraphLimiter.instance(),
  };

  final Map<String, Limiter> _customLimiters = const {};

  static Limiter? getLimiter(String key) {
    return _limiters[key];
  }

  @override
  Node? query(String rs, {Map<String, dynamic> args = const {}}) {
    // TODO: implement query
    throw UnimplementedError();
  }

  @override
  List<Node> queryList(String rs, {Map<String, dynamic> args = const {}}) {
    // TODO: implement queryList
    throw UnimplementedError();
  }

  @override
  List<Node> queryNodes(List<String> ids, {Map<String, dynamic> args = const {}}) {
    throw UnimplementedError();
  }

  @override
  String? addNode(Node node) {
    // TODO: implement addNode
    throw UnimplementedError();
  }

  @override
  bool canInsertInto(Node target, Node node) {
    // TODO: implement canInsertInto
    throw UnimplementedError();
  }

  @override
  int computeGlobalEndPosition(Node node) {
    // TODO: implement computeGlobalEndPosition
    throw UnimplementedError();
  }

  @override
  int computeGlobalStartPosition(Node node) {
    // TODO: implement computeGlobalStartPosition
    throw UnimplementedError();
  }

  @override
  TextRange computeLocalRangePosition(Node node) {
    // TODO: implement computeLocalRangePosition
    throw UnimplementedError();
  }

  @override
  TextRange computeRangePosition(Node node) {
    // TODO: implement computeRangePosition
    throw UnimplementedError();
  }

  @override
  bool convertToType(Node ownerTarget, Node node) {
    // TODO: implement convertToType
    throw UnimplementedError();
  }

  @override
  bool deleteNodesBySelection(TextSelection selection) {
    // TODO: implement deleteNodesBySelection
    throw UnimplementedError();
  }

  @override
  bool deleteText(TextSelection selection) {
    // TODO: implement deleteText
    throw UnimplementedError();
  }

  @override
  Node? getSelectedNode(TextSelection selection) {
    // TODO: implement getSelectedNode
    throw UnimplementedError();
  }

  @override
  List<Node> getSelectedNodes(TextSelection selection) {
    // TODO: implement getSelectedNodes
    throw UnimplementedError();
  }

  @override
  String getTextAtSelection(TextSelection selection) {
    // TODO: implement getTextAtSelection
    throw UnimplementedError();
  }

  @override
  String? insertNode(Node node, int offset) {
    // TODO: implement insertNode
    throw UnimplementedError();
  }

  @override
  String insertNodeAt(Node node, {List<int>? path}) {
    // TODO: implement insertNodeAt
    throw UnimplementedError();
  }

  @override
  bool insertNodeAtPath(Node node, List<int> path) {
    // TODO: implement insertNodeAtPath
    throw UnimplementedError();
  }

  @override
  bool insertText(TextSelection selection) {
    // TODO: implement insertText
    throw UnimplementedError();
  }

  @override
  bool insertTextAtNode(Node target, String text, List<int> path) {
    // TODO: implement insertTextAtNode
    throw UnimplementedError();
  }

  @override
  bool moveNodeTo(Node node, int path, {bool internally = true}) {
    // TODO: implement moveNodeTo
    throw UnimplementedError();
  }

  @override
  bool moveNodes(List<Node> nodes, int to) {
    // TODO: implement moveNodes
    throw UnimplementedError();
  }

  @override
  bool needsConvertion(Node target, Node node) {
    // TODO: implement needsConvertion
    throw UnimplementedError();
  }

  @override
  bool updateNode(Node node) {
    // TODO: implement updateNode
    throw UnimplementedError();
  }

  @override
  bool updateText(String text, Node target, {String? id}) {
    // TODO: implement updateText
    throw UnimplementedError();
  }
}
