import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/dijkstra_state.dart';
import '../models/route_graph.dart';

class RouteInfoPanel extends StatelessWidget {
  final DijkstraVisualizationState dijkstraState;
  final RouteGraph? graph;
  final LatLng? startPoint;
  final LatLng? endPoint;

  const RouteInfoPanel({
    super.key,
    required this.dijkstraState,
    required this.graph,
    required this.startPoint,
    required this.endPoint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildInstructions(),
            const SizedBox(height: 16),
            if (graph != null) _buildGraphInfo(),
            if (dijkstraState.path.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildRouteInfo(),
            ],
            if (dijkstraState.currentNode != null) ...[
              const SizedBox(height: 16),
              _buildAlgorithmStatus(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    if (startPoint == null && endPoint == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Text(
            '🗺️ Welcome to Dijkstra Route Planner!\n\n'
            '1. Tap on the map to set start point 🟢\n'
            '2. Tap again to set end point 🔴\n'
            '3. Click "Find Route" to run Dijkstra\'s algorithm\n'
            '4. Watch the algorithm explore the graph in real-time!\n\n'
            '💡 Tip: Select points on roads for best results',
            style: TextStyle(fontSize: 12),
          ),
        ),
      );
    } else if (endPoint == null) {
      return const Card(
        color: Colors.blue,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Text(
            '🎯 Great! Start point selected.\n'
            'Now tap to set the end point 🔴',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      );
    } else {
      return const Card(
        color: Colors.green,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Text(
            '✅ Both points selected!\n'
            'Ready to find the shortest path with Dijkstra\'s algorithm.\n\n'
            'Click "Find Route" to start the visualization! 🚀',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      );
    }
  }

  Widget _buildGraphInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Graph Information',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Nodes: ${graph!.nodeCount}'),
            Text('Edges: ${graph!.edgeCount}'),
            if (dijkstraState.visited.isNotEmpty) ...[
              Text('Nodes Visited: ${dijkstraState.visited.length}'),
              Text('Nodes in Queue: ${dijkstraState.inQueue.length}'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRouteInfo() {
    final totalDistance = _calculateTotalDistance();
    final totalTime = _calculateTotalTime();
    final visitedNodes = dijkstraState.visited.length;
    final totalNodes = graph?.nodeCount ?? 0;

    return Card(
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Route Found! 🎉',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                children: [
                  _buildInfoRow(Icons.route, 'Path Length', '${dijkstraState.path.length} nodes'),
                  if (totalDistance > 0) ...[
                    _buildInfoRow(Icons.straighten, 'Total Distance', '${totalDistance.toStringAsFixed(2)} km'),
                    _buildInfoRow(Icons.schedule, 'Estimated Time', '${totalTime.toStringAsFixed(1)} minutes'),
                  ],
                  _buildInfoRow(Icons.analytics, 'Nodes Explored', '$visitedNodes / $totalNodes'),
                  _buildInfoRow(
                    Icons.speed,
                    'Algorithm Efficiency',
                    '${(visitedNodes / totalNodes * 100).toStringAsFixed(1)}% of graph',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: Colors.green[700], size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Dijkstra found the optimal shortest path!',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'This algorithm guarantees the shortest path by exploring nodes in order of distance.',
                    style: TextStyle(
                      color: Colors.green[600],
                      fontSize: 9,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Text('$label:', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 11, color: Colors.blue)),
        ],
      ),
    );
  }

  Widget _buildAlgorithmStatus() {
    final visitedCount = dijkstraState.visited.length;
    final queueSize = dijkstraState.inQueue.length;
    final totalNodes = graph?.nodeCount ?? 0;

    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (dijkstraState.currentNode != null) {
      statusText = '🔄 Algorithm Running...\nExploring node ${dijkstraState.currentNode}';
      statusColor = Colors.orange[100]!;
      statusIcon = Icons.play_arrow;
    } else if (dijkstraState.path.isNotEmpty) {
      statusText = '🎉 Route Found!\nDijkstra completed successfully';
      statusColor = Colors.green[100]!;
      statusIcon = Icons.check_circle;
    } else if (visitedCount > 0) {
      statusText = '⏸️ Algorithm Paused\nProgress: $visitedCount/$totalNodes nodes';
      statusColor = Colors.blue[100]!;
      statusIcon = Icons.pause;
    } else {
      statusText = '⏰ Ready to Start\nClick "Find Route" to begin';
      statusColor = Colors.grey[200]!;
      statusIcon = Icons.play_circle_outline;
    }

    return Card(
      color: statusColor,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Algorithm Status',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(statusText, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            if (visitedCount > 0) ...[
              Text(
                'Progress: $visitedCount visited, $queueSize in queue',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
              const SizedBox(height: 4),
            ],
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Legend:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 2,
          children: [
            _buildCompactLegendItem(Colors.grey, 'Unvisited'),
            _buildCompactLegendItem(Colors.yellow, 'Queue'),
            _buildCompactLegendItem(Colors.orange, 'Current'),
            _buildCompactLegendItem(Colors.lightBlue, 'Visited'),
            _buildCompactLegendItem(Colors.blue, 'Path'),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 0.5),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }

  double _calculateTotalDistance() {
    if (graph == null || dijkstraState.path.length < 2) return 0.0;

    double total = 0.0;
    for (int i = 0; i < dijkstraState.path.length - 1; i++) {
      final fromNodeId = dijkstraState.path[i];
      final toNodeId = dijkstraState.path[i + 1];

      final edges = graph!.getNeighbors(fromNodeId);
      for (final edge in edges) {
        if (edge.toNodeId == toNodeId) {
          total += edge.distance;
          break;
        }
      }
    }
    return total;
  }

  double _calculateTotalTime() {
    if (graph == null || dijkstraState.path.length < 2) return 0.0;

    double total = 0.0;
    for (int i = 0; i < dijkstraState.path.length - 1; i++) {
      final fromNodeId = dijkstraState.path[i];
      final toNodeId = dijkstraState.path[i + 1];

      final edges = graph!.getNeighbors(fromNodeId);
      for (final edge in edges) {
        if (edge.toNodeId == toNodeId) {
          total += edge.travelTime;
          break;
        }
      }
    }
    return total;
  }
}