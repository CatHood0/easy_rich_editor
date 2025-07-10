import 'package:collection/collection.dart';
import 'package:easy_rich_editor/src/core/api/nodes/node.dart';

import '../tree.dart';

const ListEquality _equality = ListEquality();

enum NodeTypeChange {
  update,
  move,
  deletion,
  insertion,
}

enum SnapshotLevel {
  // only ids are saved
  none,
  // some fields are modified, like text, or attributes
  partial,
  // when a node change completely. Usual when a node is deleted
  full
}

class NodeChange {
  final NodeTypeChange type;
  final List<String> nodeIds;
  final Map<String, dynamic> info;
  final SnapshotLevel _snapshotLevel;
  final dynamic _stateStorage;
  final DateTime _timestamp;

  NodeChange._internal({
    required this.type,
    required this.nodeIds,
    required this.info,
    required SnapshotLevel snapshotLevel,
    required dynamic stateStorage,
  })  : _snapshotLevel = snapshotLevel,
        _stateStorage = stateStorage,
        _timestamp = DateTime.now();

  factory NodeChange.generic({
    required NodeTypeChange type,
    required List<Node> nodes,
    Map<String, dynamic> info = const {},
    SnapshotLevel snapshotLevel = SnapshotLevel.none,
  }) {
    dynamic stateStorage;

    switch (snapshotLevel) {
      case SnapshotLevel.full:
        stateStorage = {for (var n in nodes) n.id: n.deepCopy()};
        break;
      case SnapshotLevel.partial:
        stateStorage = _capturePartialState(nodes);
        break;
      case SnapshotLevel.none:
        stateStorage = null;
        break;
    }

    return NodeChange._internal(
      type: type,
      nodeIds: nodes.map((n) => n.id).toList(),
      info: info,
      snapshotLevel: snapshotLevel,
      stateStorage: stateStorage,
    );
  }

  factory NodeChange.insertion({
    required List<Node> nodes,
    required Map<String, List<int>> originalPositions,
    required Map<String, Node> originalRootOwners,
    SnapshotLevel snapshotLevel = SnapshotLevel.none,
  }) {
    return NodeChange.generic(
      type: NodeTypeChange.insertion,
      nodes: nodes,
      info: {
        "original_pos": originalPositions,
        "original_owners": originalRootOwners,
      },
      snapshotLevel: snapshotLevel,
    );
  }

  factory NodeChange.update({
    required List<Node> nodes,
    required Map<String, dynamic> changedValues,
    SnapshotLevel snapshotLevel = SnapshotLevel.partial,
  }) {
    return NodeChange.generic(
      type: NodeTypeChange.update,
      nodes: nodes,
      info: {
        "changed_attributes": changedValues['attributes'],
        "changed_text": changedValues['text'],
      },
      snapshotLevel: snapshotLevel,
    );
  }

  factory NodeChange.deletion({
    required List<Node> nodes,
    required Map<String, List<int>> originalPositions,
    required Map<String, Node> originalRootOwners,
  }) {
    return NodeChange.generic(
      type: NodeTypeChange.deletion,
      nodes: nodes,
      info: {
        "original_pos": originalPositions,
        "original_owners": originalRootOwners,
      },
      snapshotLevel: SnapshotLevel.full,
    );
  }

  factory NodeChange.move({
    required List<Node> nodes,
    required Map<String, List<int>> originalPositions,
    required Map<String, Node> originalRootOwners,
    required Map<String, List<int>> newPositions,
    Node? newRootOwner,
    SnapshotLevel snapshotLevel = SnapshotLevel.none,
  }) {
    return NodeChange.generic(
      type: NodeTypeChange.move,
      nodes: nodes,
      info: {
        "original_pos": originalPositions,
        "original_owners": originalRootOwners,
        "new_pos": newPositions,
        if (newRootOwner != null) "new_owner": newRootOwner,
      },
      snapshotLevel: snapshotLevel,
    );
  }

  static Map<String, Map<String, dynamic>> _capturePartialState(
      List<Node> nodes) {
    return {for (var n in nodes) n.id: n.getChangedValues()};
  }

  List<Node> restoreNodes([Tree? repo]) {
    switch (_snapshotLevel) {
      case SnapshotLevel.full:
        return _stateStorage.values.toList() as List<Node>;
      case SnapshotLevel.partial:
        if (repo == null) {
          throw ArgumentError('We need Tree for partial undo states');
        }
        return _restorePartialNodes(repo);
      case SnapshotLevel.none:
        if (repo == null) {
          throw ArgumentError('We need Tree for undo states');
        }
        return repo.queryNodes(nodeIds);
    }
  }

  List<Node> _restorePartialNodes(Tree repo) {
    final Map<String, Map<String, dynamic>> partialData =
        _stateStorage as Map<String, Map<String, dynamic>>;
    final nodes = repo.queryNodes(nodeIds);
    return nodes.map((n) {
      final changes = partialData[n.id];
      return changes != null ? n.updateValues(changes) : n;
    }).toList();
  }

  @override
  bool operator ==(covariant NodeChange other) {
    return type == other.type && _equality.equals(nodeIds, other.nodeIds);
  }

  @override
  int get hashCode => Object.hashAll([type, nodeIds]);

  // Métodos para serialización/deserialización
  Map<String, dynamic> toJson() {
    return {
      'type': type.index,
      'nodeIds': nodeIds,
      'info': info,
      'snapshotLevel': _snapshotLevel.index,
      'stateStorage': _serializeStateStorage(),
      'timestamp': _timestamp.toIso8601String(),
    };
  }

  dynamic _serializeStateStorage() {
    if (_stateStorage == null) return null;

    if (_stateStorage is Map<String, Node>) {
      return {
        'type': 'full',
        'data': (_stateStorage).map((k, v) => MapEntry(k, v.toJson())),
      };
    } else if (_stateStorage is Map<String, Map<String, dynamic>>) {
      return {
        'type': 'partial',
        'data': _stateStorage,
      };
    }
    return null;
  }
}
