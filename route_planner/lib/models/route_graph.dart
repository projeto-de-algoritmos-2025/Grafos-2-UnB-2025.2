import 'osm_node.dart';
import 'graph_edge.dart';

class RouteGraph {
  final Map<int, OSMNode> nodes = {};
  final Map<int, List<GraphEdge>> adjacencyList = {};

  void addNode(OSMNode node) {
    nodes[node.id] = node;
    adjacencyList[node.id] ??= [];
  }

  void addEdge(GraphEdge edge) {
    addNode(nodes[edge.fromNodeId]!);
    addNode(nodes[edge.toNodeId]!);

    adjacencyList[edge.fromNodeId]!.add(edge);
  }

  void addBidirectionalEdge(GraphEdge edge) {
    addEdge(edge);

    final reverseEdge = GraphEdge(
      fromNodeId: edge.toNodeId,
      toNodeId: edge.fromNodeId,
      distance: edge.distance,
      travelTime: edge.travelTime,
      roadType: edge.roadType,
    );

    addEdge(reverseEdge);
  }

  List<GraphEdge> getNeighbors(int nodeId) {
    return adjacencyList[nodeId] ?? [];
  }

  OSMNode? getNode(int nodeId) {
    return nodes[nodeId];
  }

  List<int> getAllNodeIds() {
    return nodes.keys.toList();
  }

  int get nodeCount => nodes.length;
  int get edgeCount => adjacencyList.values.fold(0, (sum, edges) => sum + edges.length);

  void analyzeConnectivity() {
    print('🔬 Analyzing graph connectivity...');

    int isolatedNodes = 0;
    int deadEndNodes = 0;
    final Map<int, int> degreeDistribution = {};

    for (final nodeId in getAllNodeIds()) {
      final outgoingEdges = getNeighbors(nodeId).length;

      // Count incoming edges
      int incomingEdges = 0;
      for (final otherNodeId in getAllNodeIds()) {
        if (otherNodeId != nodeId) {
          final otherEdges = getNeighbors(otherNodeId);
          for (final edge in otherEdges) {
            if (edge.toNodeId == nodeId) {
              incomingEdges++;
            }
          }
        }
      }

      final totalDegree = outgoingEdges + incomingEdges;
      degreeDistribution[totalDegree] = (degreeDistribution[totalDegree] ?? 0) + 1;

      if (totalDegree == 0) {
        isolatedNodes++;
      } else if (outgoingEdges == 0) {
        deadEndNodes++;
      }
    }

    print('📊 Connectivity Analysis:');
    print('   🏝️ Isolated nodes (no connections): $isolatedNodes');
    print('   🚧 Dead-end nodes (no outgoing edges): $deadEndNodes');
    print('   📈 Degree distribution:');

    final sortedDegrees = degreeDistribution.keys.toList()..sort();
    for (final degree in sortedDegrees.take(10)) { // Show first 10
      print('      Degree $degree: ${degreeDistribution[degree]} nodes');
    }
    if (sortedDegrees.length > 10) {
      print('      ... and ${sortedDegrees.length - 10} more degree values');
    }
  }

  /// Check if there's a path between two nodes using BFS
  bool isConnected(int startNodeId, int endNodeId) {
    if (startNodeId == endNodeId) return true;

    final visited = <int>{};
    final queue = <int>[startNodeId];
    visited.add(startNodeId);

    while (queue.isNotEmpty) {
      final currentNodeId = queue.removeAt(0);

      if (currentNodeId == endNodeId) {
        return true;
      }

      for (final edge in getNeighbors(currentNodeId)) {
        if (!visited.contains(edge.toNodeId)) {
          visited.add(edge.toNodeId);
          queue.add(edge.toNodeId);
        }
      }
    }

    return false;
  }

  @override
  String toString() => 'RouteGraph(nodes: $nodeCount, edges: $edgeCount)';
}