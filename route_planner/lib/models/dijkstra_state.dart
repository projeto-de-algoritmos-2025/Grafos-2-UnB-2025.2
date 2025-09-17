class DijkstraNode {
  final int nodeId;
  final double distance;
  final int? previousNodeId;

  const DijkstraNode({
    required this.nodeId,
    required this.distance,
    this.previousNodeId,
  });
}

enum NodeVisualState {
  unvisited,
  inQueue,
  processing,
  visited,
  inPath,
}

class DijkstraVisualizationState {
  final Map<int, double> distances;
  final Map<int, int?> previous;
  final Set<int> visited;
  final Set<int> inQueue;
  final int? currentNode;
  final List<int> path;
  final Map<int, NodeVisualState> nodeStates;

  const DijkstraVisualizationState({
    required this.distances,
    required this.previous,
    required this.visited,
    required this.inQueue,
    this.currentNode,
    required this.path,
    required this.nodeStates,
  });

  DijkstraVisualizationState copyWith({
    Map<int, double>? distances,
    Map<int, int?>? previous,
    Set<int>? visited,
    Set<int>? inQueue,
    int? currentNode,
    List<int>? path,
    Map<int, NodeVisualState>? nodeStates,
  }) {
    return DijkstraVisualizationState(
      distances: distances ?? Map.from(this.distances),
      previous: previous ?? Map.from(this.previous),
      visited: visited ?? Set.from(this.visited),
      inQueue: inQueue ?? Set.from(this.inQueue),
      currentNode: currentNode ?? this.currentNode,
      path: path ?? List.from(this.path),
      nodeStates: nodeStates ?? Map.from(this.nodeStates),
    );
  }

  static DijkstraVisualizationState initial() {
    return const DijkstraVisualizationState(
      distances: {},
      previous: {},
      visited: {},
      inQueue: {},
      currentNode: null,
      path: [],
      nodeStates: {},
    );
  }
}