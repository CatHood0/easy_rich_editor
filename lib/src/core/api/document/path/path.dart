import 'dart:math';
import 'package:flutter/foundation.dart';

import '../../../../../easy_rich_editor.dart';

typedef NodeDepthPath = List<int>;
typedef FragmentPath = List<int>;

extension MinimalPathExtension on int {
  int get prev => this - 1;
  int get next => this + 1;
}

extension PathExtensions on NodeDepthPath {
  bool equals(NodeDepthPath other) {
    return listEquals(this, other);
  }

  bool operator >=(NodeDepthPath other) {
    if (equals(other)) {
      return true;
    }
    return this > other;
  }

  bool operator >(NodeDepthPath other) {
    if (equals(other)) {
      return false;
    }
    final length = min(this.length, other.length);
    for (var i = 0; i < length; i++) {
      if (this[i] < other[i]) {
        return false;
      } else if (this[i] > other[i]) {
        return true;
      }
    }
    if (this.length < other.length) {
      return false;
    }
    return true;
  }

  bool operator <=(NodeDepthPath other) {
    if (equals(other)) {
      return true;
    }
    return this < other;
  }

  bool operator <(NodeDepthPath other) {
    if (equals(other)) {
      return false;
    }
    final length = min(this.length, other.length);
    for (var i = 0; i < length; i++) {
      if (this[i] > other[i]) {
        return false;
      } else if (this[i] < other[i]) {
        return true;
      }
    }
    if (this.length > other.length) {
      return false;
    }
    return true;
  }

  NodeDepthPath get next {
    NodeDepthPath nextPath = NodeDepthPath.from(this, growable: true);
    if (isEmpty) {
      return nextPath;
    }
    final last = nextPath.last;
    return nextPath
      ..removeLast()
      ..add(last + 1);
  }

  NodeDepthPath nextNPath(int n) {
    NodeDepthPath nextPath = NodeDepthPath.from(this, growable: true);
    if (isEmpty) {
      return nextPath;
    }
    final last = nextPath.last;
    return nextPath
      ..removeLast()
      ..add(last + n);
  }

  NodeDepthPath child(int index) {
    return NodeDepthPath.from(this, growable: true)..add(index);
  }

  NodeDepthPath get previous {
    NodeDepthPath previousPath = NodeDepthPath.from(this, growable: true);
    if (isEmpty) {
      return previousPath;
    }
    final last = previousPath.last;
    return previousPath
      ..removeLast()
      ..add(max(0, last - 1));
  }

  NodeDepthPath previousNPath(int n) {
    NodeDepthPath previousPath = NodeDepthPath.from(this, growable: true);
    if (isEmpty) {
      return previousPath;
    }
    final last = previousPath.last;
    return previousPath
      ..removeLast()
      ..add(max(0, last - n));
  }

  NodeDepthPath get parent {
    if (isEmpty) {
      return this;
    }
    return NodeDepthPath.from(this, growable: true)..removeLast();
  }

  bool isAncestorOf(NodeDepthPath other) {
    if (isEmpty) {
      return true;
    }
    if (other.isEmpty) {
      return false;
    }
    if (length >= other.length) {
      return false;
    }
    for (var i = 0; i < length; i++) {
      if (this[i] != other[i]) {
        return false;
      }
    }
    return true;
  }

  // if isSameDepth is true, the path must be the same depth as the selection
  bool inSelection(
    NodeSelection? selection, {
    bool isSameDepth = false,
  }) {
    selection = selection?.normalized;
    bool result = selection != null &&
        selection.start.path <= this &&
        this <= selection.end.path;
    if (isSameDepth) {
      return result && selection.start.path.length == length;
    }
    return result;
  }
}
