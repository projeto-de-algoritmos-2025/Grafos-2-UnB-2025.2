import 'package:flutter/foundation.dart';
import '../models/route_graph.dart';
import '../models/dijkstra_state.dart';
import 'priority_queue.dart';

class DijkstraAlgorithm extends ChangeNotifier {
  DijkstraVisualizationState _state = DijkstraVisualizationState.initial();
  bool _isRunning = false;
  bool _isPaused = false;
  String _weightCriteria = 'distance';

  DijkstraVisualizationState get state => _state;
  bool get isRunning => _isRunning;
  bool get isPaused => _isPaused;
  String get weightCriteria => _weightCriteria;

  void setWeightCriteria(String criteria) {
    _weightCriteria = criteria;
    notifyListeners();
  }

  Future<List<int>> findShortestPath({
    required RouteGraph graph,
    required int startNodeId,
    required int endNodeId,
    bool animate = true,
    int delayMs = 100,
  }) async {
    print('🚀 Starting Dijkstra algorithm');
    print('📊 Graph stats: ${graph.nodeCount} nodes, ${graph.edgeCount} edges');
    print('🎯 Start node: $startNodeId, End node: $endNodeId');
    print('⚙️ Weight criteria: $_weightCriteria');

    _isRunning = true;
    _isPaused = false;

    final distances = <int, double>{};
    final previous = <int, int?>{};
    final visited = <int>{};
    final pq = PriorityQueue<DijkstraNode>(
      (a, b) => a.distance.compareTo(b.distance),
    );

    // Verify start and end nodes exist in graph
    if (!graph.getAllNodeIds().contains(startNodeId)) {
      print('❌ ERROR: Start node $startNodeId not found in graph');
      throw Exception('Start node $startNodeId not found in graph');
    }

    if (!graph.getAllNodeIds().contains(endNodeId)) {
      print('❌ ERROR: End node $endNodeId not found in graph');
      throw Exception('End node $endNodeId not found in graph');
    }

    print('✅ Both start and end nodes exist in graph');

    for (final nodeId in graph.getAllNodeIds()) {
      distances[nodeId] = double.infinity;
      previous[nodeId] = null;
    }

    distances[startNodeId] = 0.0;
    pq.add(DijkstraNode(nodeId: startNodeId, distance: 0.0));

    print('🏁 Initial setup complete. Priority queue size: ${pq.length}');

    _updateState(
      distances: distances,
      previous: previous,
      visited: visited,
      inQueue: {startNodeId},
      nodeStates: _updateNodeStates(
        graph.getAllNodeIds(),
        visited,
        {startNodeId},
        null,
        [],
      ),
    );

    if (animate) {
      await Future.delayed(Duration(milliseconds: delayMs));
      notifyListeners();
    }

    int iterationCount = 0;
    while (pq.isNotEmpty && !visited.contains(endNodeId)) {
      iterationCount++;
      if (!_isRunning) {
        print('⏹️ Algorithm stopped by user at iteration $iterationCount');
        break;
      }

      while (_isPaused && _isRunning) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      final currentDijkstraNode = pq.removeFirst();
      final currentNodeId = currentDijkstraNode.nodeId;

      if (visited.contains(currentNodeId)) {
        if (iterationCount % 50 == 0) {
          print(
            '⚠️ Iteration $iterationCount: Skipping already visited node $currentNodeId',
          );
        }
        continue;
      }

      visited.add(currentNodeId);

      print(
        '🔄 Iteration $iterationCount: Processing node $currentNodeId (distance: ${distances[currentNodeId]!.toStringAsFixed(3)})',
      );
      print('   📍 Queue size: ${pq.length}, Visited count: ${visited.length}');

      // Check if we found the target
      if (currentNodeId == endNodeId) {
        print('🎉 Found target node $endNodeId at iteration $iterationCount!');
        break;
      }

      _updateState(
        distances: distances,
        previous: previous,
        visited: visited,
        inQueue: pq.map((node) => node.nodeId).toSet(),
        currentNode: currentNodeId,
        nodeStates: _updateNodeStates(
          graph.getAllNodeIds(),
          visited,
          pq.map((node) => node.nodeId).toSet(),
          currentNodeId,
          [],
        ),
      );

      if (animate) {
        await Future.delayed(Duration(milliseconds: delayMs));
        notifyListeners();
      }

      final neighbors = graph.getNeighbors(currentNodeId);
      print('   👥 Node $currentNodeId has ${neighbors.length} neighbors');

      if (neighbors.isEmpty) {
        print('   ⚠️ WARNING: Node $currentNodeId has no outgoing edges!');
      }

      int updatedNeighbors = 0;
      for (final edge in neighbors) {
        final neighborId = edge.toNodeId;
        final edgeWeight = edge.getWeight(_weightCriteria);

        if (!visited.contains(neighborId)) {
          final newDistance = distances[currentNodeId]! + edgeWeight;

          if (newDistance < distances[neighborId]!) {
            distances[neighborId] = newDistance;
            previous[neighborId] = currentNodeId;
            pq.add(
              DijkstraNode(
                nodeId: neighborId,
                distance: newDistance,
                previousNodeId: currentNodeId,
              ),
            );
            updatedNeighbors++;

            if (iterationCount <= 10 || iterationCount % 100 == 0) {
              print(
                '   ✅ Updated neighbor $neighborId: new distance ${newDistance.toStringAsFixed(3)} (edge weight: ${edgeWeight.toStringAsFixed(3)})',
              );
            }
          }
        }
      }

      print(
        '   📝 Updated $updatedNeighbors neighbors out of ${neighbors.length}',
      );

      // Safety check for infinite loops
      if (iterationCount > graph.nodeCount * 2) {
        print(
          '❌ ERROR: Algorithm exceeded maximum iterations (${graph.nodeCount * 2}). Possible infinite loop or disconnected graph.',
        );
        break;
      }
    }

    print('🏁 Algorithm finished after $iterationCount iterations');
    print('📊 Final stats: Visited ${visited.length}/${graph.nodeCount} nodes');

    if (pq.isEmpty && !visited.contains(endNodeId)) {
      print(
        '❌ ERROR: Priority queue empty but end node $endNodeId not reached. Graph may be disconnected.',
      );
    }

    final path = _reconstructPath(previous, startNodeId, endNodeId);

    if (path.isEmpty) {
      print('❌ ERROR: No path found from $startNodeId to $endNodeId');
      print('🔍 Debugging info:');
      print('   - Start node in visited: ${visited.contains(startNodeId)}');
      print('   - End node in visited: ${visited.contains(endNodeId)}');
      print('   - End node distance: ${distances[endNodeId]}');
      print('   - End node previous: ${previous[endNodeId]}');
    } else {
      print('✅ Path found! Length: ${path.length} nodes');
      print(
        '🗺️ Path: ${path.take(10).toList()}${path.length > 10 ? '... (${path.length - 10} more)' : ''}',
      );
    }

    _updateState(
      distances: distances,
      previous: previous,
      visited: visited,
      inQueue: {},
      currentNode: null,
      path: path,
      nodeStates: _updateNodeStates(
        graph.getAllNodeIds(),
        visited,
        {},
        null,
        path,
      ),
    );

    _isRunning = false;
    notifyListeners();
    return path;
  }

  List<int> _reconstructPath(
    Map<int, int?> previous,
    int startNodeId,
    int endNodeId,
  ) {
    final path = <int>[];
    int? current = endNodeId;

    while (current != null) {
      path.add(current);
      current = previous[current];

      if (path.length > previous.length) {
        return [];
      }
    }

    if (path.last == startNodeId) {
      return path.reversed.toList();
    }

    return [];
  }

  Map<int, NodeVisualState> _updateNodeStates(
    List<int> allNodes,
    Set<int> visited,
    Set<int> inQueue,
    int? currentNode,
    List<int> path,
  ) {
    final nodeStates = <int, NodeVisualState>{};

    for (final nodeId in allNodes) {
      if (path.contains(nodeId)) {
        nodeStates[nodeId] = NodeVisualState.inPath;
      } else if (nodeId == currentNode) {
        nodeStates[nodeId] = NodeVisualState.processing;
      } else if (visited.contains(nodeId)) {
        nodeStates[nodeId] = NodeVisualState.visited;
      } else if (inQueue.contains(nodeId)) {
        nodeStates[nodeId] = NodeVisualState.inQueue;
      } else {
        nodeStates[nodeId] = NodeVisualState.unvisited;
      }
    }

    return nodeStates;
  }

  void _updateState({
    Map<int, double>? distances,
    Map<int, int?>? previous,
    Set<int>? visited,
    Set<int>? inQueue,
    int? currentNode,
    List<int>? path,
    Map<int, NodeVisualState>? nodeStates,
  }) {
    _state = _state.copyWith(
      distances: distances,
      previous: previous,
      visited: visited,
      inQueue: inQueue,
      currentNode: currentNode,
      path: path,
      nodeStates: nodeStates,
    );
  }

  void pause() {
    _isPaused = true;
    notifyListeners();
  }

  void resume() {
    _isPaused = false;
    notifyListeners();
  }

  void stop() {
    _isRunning = false;
    _isPaused = false;
    notifyListeners();
  }

  void reset() {
    _isRunning = false;
    _isPaused = false;
    _state = DijkstraVisualizationState.initial();
    notifyListeners();
  }
}
