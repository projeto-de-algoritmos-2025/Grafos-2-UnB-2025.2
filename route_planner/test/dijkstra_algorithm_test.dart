import 'package:flutter_test/flutter_test.dart';
import 'package:route_planner/models/osm_node.dart';
import 'package:route_planner/models/graph_edge.dart';
import 'package:route_planner/models/route_graph.dart';
import 'package:route_planner/algorithms/dijkstra_algorithm.dart';

void main() {
  group('Dijkstra Algorithm Tests', () {
    late RouteGraph testGraph;
    late DijkstraAlgorithm algorithm;

    setUp(() {
      testGraph = RouteGraph();
      algorithm = DijkstraAlgorithm();

      // Create a simple test graph with 4 nodes
      final node1 = OSMNode(id: 1, latitude: -15.7942, longitude: -47.8822);
      final node2 = OSMNode(id: 2, latitude: -15.7943, longitude: -47.8823);
      final node3 = OSMNode(id: 3, latitude: -15.7944, longitude: -47.8824);
      final node4 = OSMNode(id: 4, latitude: -15.7945, longitude: -47.8825);

      testGraph.addNode(node1);
      testGraph.addNode(node2);
      testGraph.addNode(node3);
      testGraph.addNode(node4);

      // Add edges: 1->2 (dist: 1), 1->3 (dist: 4), 2->3 (dist: 2), 2->4 (dist: 5), 3->4 (dist: 1)
      testGraph.addEdge(GraphEdge(
        fromNodeId: 1,
        toNodeId: 2,
        distance: 1.0,
        travelTime: 1.0,
        roadType: 'primary',
      ));

      testGraph.addEdge(GraphEdge(
        fromNodeId: 1,
        toNodeId: 3,
        distance: 4.0,
        travelTime: 4.0,
        roadType: 'primary',
      ));

      testGraph.addEdge(GraphEdge(
        fromNodeId: 2,
        toNodeId: 3,
        distance: 2.0,
        travelTime: 2.0,
        roadType: 'primary',
      ));

      testGraph.addEdge(GraphEdge(
        fromNodeId: 2,
        toNodeId: 4,
        distance: 5.0,
        travelTime: 5.0,
        roadType: 'primary',
      ));

      testGraph.addEdge(GraphEdge(
        fromNodeId: 3,
        toNodeId: 4,
        distance: 1.0,
        travelTime: 1.0,
        roadType: 'primary',
      ));
    });

    test('should find shortest path', () async {
      final path = await algorithm.findShortestPath(
        graph: testGraph,
        startNodeId: 1,
        endNodeId: 4,
        animate: false,
      );

      // Expected shortest path: 1 -> 2 -> 3 -> 4 (total distance: 4)
      expect(path, equals([1, 2, 3, 4]));
      expect(algorithm.state.path, equals([1, 2, 3, 4]));
    });

    test('should handle different weight criteria', () async {
      algorithm.setWeightCriteria('time');

      final path = await algorithm.findShortestPath(
        graph: testGraph,
        startNodeId: 1,
        endNodeId: 4,
        animate: false,
      );

      // Should still be the same path since distances and times are equal in this test
      expect(path, equals([1, 2, 3, 4]));
    });

    test('should track visited nodes', () async {
      await algorithm.findShortestPath(
        graph: testGraph,
        startNodeId: 1,
        endNodeId: 4,
        animate: false,
      );

      expect(algorithm.state.visited.contains(1), true);
      expect(algorithm.state.visited.contains(2), true);
      expect(algorithm.state.visited.contains(3), true);
      expect(algorithm.state.visited.contains(4), true);
    });

    test('should reset algorithm state', () {
      algorithm.reset();

      expect(algorithm.state.path, isEmpty);
      expect(algorithm.state.visited, isEmpty);
      expect(algorithm.state.currentNode, isNull);
      expect(algorithm.isRunning, false);
      expect(algorithm.isPaused, false);
    });
  });
}