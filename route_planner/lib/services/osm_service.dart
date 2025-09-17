import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/osm_node.dart';
import '../models/osm_way.dart';
import '../models/route_graph.dart';
import '../models/graph_edge.dart';

class OSMService {
  static const String _overpassUrl = 'https://overpass-api.de/api/interpreter';

  final Distance _distance = const Distance();

  Future<RouteGraph> fetchRoadNetwork(LatLng southwest, LatLng northeast) async {
    print('🌍 Fetching OSM data for bounds:');
    print('   SW: ${southwest.latitude}, ${southwest.longitude}');
    print('   NE: ${northeast.latitude}, ${northeast.longitude}');

    final query = _buildOverpassQuery(southwest, northeast);
    print('📝 Overpass query length: ${query.length} characters');

    try {
      final response = await http.post(
        Uri.parse(_overpassUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'data=$query',
      );

      print('🌐 HTTP Response: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch OSM data: ${response.statusCode}');
      }

      final jsonData = json.decode(response.body);
      print('📊 Raw OSM data elements: ${jsonData['elements']?.length ?? 0}');

      return _parseOverpassResponse(jsonData);
    } catch (e) {
      print('❌ Error fetching OSM data: $e');
      throw Exception('Error fetching OSM data: $e');
    }
  }

  String _buildOverpassQuery(LatLng southwest, LatLng northeast) {
    return '''
[out:json][timeout:30];
(
  way["highway"~"^(motorway|trunk|primary|secondary|tertiary|residential|service)"]["highway"!~"^(footway|cycleway|path|track|steps|pedestrian)"]
  (${southwest.latitude},${southwest.longitude},${northeast.latitude},${northeast.longitude});
);
out geom;
    ''';
  }

  RouteGraph _parseOverpassResponse(Map<String, dynamic> data) {
    print('🔧 Parsing OSM response...');
    final graph = RouteGraph();
    final List<dynamic> elements = data['elements'] ?? [];

    final Map<int, OSMNode> allNodes = {};
    final List<OSMWay> ways = [];
    final Map<String, int> wayTypeCount = {};

    print('📋 Processing ${elements.length} elements...');

    for (final element in elements) {
      if (element['type'] == 'way') {
        final way = OSMWay.fromJson(element);
        ways.add(way);

        // Count way types for debugging
        final highway = way.highway ?? 'unknown';
        wayTypeCount[highway] = (wayTypeCount[highway] ?? 0) + 1;

        final List<dynamic> geometry = element['geometry'] ?? [];
        for (int i = 0; i < geometry.length && i < way.nodeIds.length; i++) {
          final nodeData = geometry[i];
          final node = OSMNode(
            id: way.nodeIds[i],
            latitude: nodeData['lat']?.toDouble() ?? 0.0,
            longitude: nodeData['lon']?.toDouble() ?? 0.0,
          );
          allNodes[node.id] = node;
        }
      }
    }

    print('📈 Way types found:');
    wayTypeCount.forEach((type, count) {
      print('   $type: $count ways');
    });

    print('🎯 Total nodes extracted: ${allNodes.length}');
    print('🛣️  Total ways extracted: ${ways.length}');

    for (final node in allNodes.values) {
      graph.addNode(node);
    }

    int edgesAdded = 0;
    int skippedWays = 0;

    for (final way in ways) {
      if (way.nodeIds.length < 2) {
        skippedWays++;
        continue;
      }

      for (int i = 0; i < way.nodeIds.length - 1; i++) {
        final fromNodeId = way.nodeIds[i];
        final toNodeId = way.nodeIds[i + 1];

        final fromNode = allNodes[fromNodeId];
        final toNode = allNodes[toNodeId];

        if (fromNode == null || toNode == null) {
          print('⚠️ WARNING: Missing node data for edge $fromNodeId -> $toNodeId');
          continue;
        }

        final distance = _distance.as(
          LengthUnit.Kilometer,
          fromNode.latLng,
          toNode.latLng,
        );

        final travelTime = (distance / way.speedLimit) * 60;

        final edge = GraphEdge(
          fromNodeId: fromNodeId,
          toNodeId: toNodeId,
          distance: distance,
          travelTime: travelTime,
          roadType: way.highway ?? 'unknown',
        );

        if (way.isOneway) {
          graph.addEdge(edge);
          edgesAdded++;
        } else {
          graph.addBidirectionalEdge(edge);
          edgesAdded += 2; // Bidirectional adds 2 edges
        }
      }
    }

    print('✅ Graph construction complete:');
    print('   🎯 Nodes: ${graph.nodeCount}');
    print('   🔗 Edges: ${graph.edgeCount} (added: $edgesAdded)');
    print('   ⚠️ Skipped ways: $skippedWays');

    return graph;
  }

  Future<int> findNearestNode(RouteGraph graph, LatLng target) async {
    print('🎯 Finding nearest node to target: ${target.latitude}, ${target.longitude}');

    final allNodeIds = graph.getAllNodeIds();
    print('🔍 Searching through ${allNodeIds.length} nodes...');

    // Find nodes sorted by distance
    final nodeDistances = <Map<String, dynamic>>[];

    for (final nodeId in allNodeIds) {
      final node = graph.getNode(nodeId)!;
      final distance = _distance.as(
        LengthUnit.Meter,
        node.latLng,
        target,
      );

      final neighbors = graph.getNeighbors(nodeId).length;

      nodeDistances.add({
        'nodeId': nodeId,
        'distance': distance,
        'hasConnections': neighbors > 0,
      });
    }

    // Sort by distance
    nodeDistances.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));

    // Prefer connected nodes - look at closest 5 nodes and pick the first one with connections
    for (int i = 0; i < nodeDistances.length.clamp(0, 5); i++) {
      final nodeData = nodeDistances[i];
      if (nodeData['hasConnections'] as bool) {
        final bestNodeId = nodeData['nodeId'] as int;
        print('✅ Best connected node: $bestNodeId (distance: ${(nodeData['distance'] as double).toStringAsFixed(2)}m)');

        final neighbors = graph.getNeighbors(bestNodeId);
        print('🔗 Node has ${neighbors.length} outgoing edges');

        return bestNodeId;
      }
    }

    // If no connected nodes in top 5, just return the closest one
    if (nodeDistances.isNotEmpty) {
      final nearestNodeId = nodeDistances.first['nodeId'] as int;
      final distance = nodeDistances.first['distance'] as double;

      print('⚠️ WARNING: Using nearest node $nearestNodeId (distance: ${distance.toStringAsFixed(2)}m) but it might be disconnected');

      return nearestNodeId;
    }

    print('❌ ERROR: No nodes found in the graph');
    throw Exception('No nodes found in the graph');
  }
}