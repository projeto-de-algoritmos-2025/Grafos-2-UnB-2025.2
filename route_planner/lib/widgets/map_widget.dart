import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/route_graph.dart';
import '../models/dijkstra_state.dart';

class RouteMapWidget extends StatelessWidget {
  final MapController mapController;
  final RouteGraph? graph;
  final LatLng? startPoint;
  final LatLng? endPoint;
  final DijkstraVisualizationState dijkstraState;
  final Function(LatLng) onMapTap;

  const RouteMapWidget({
    super.key,
    required this.mapController,
    required this.graph,
    required this.startPoint,
    required this.endPoint,
    required this.dijkstraState,
    required this.onMapTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: const LatLng(-15.7942, -47.8822), // Brasília
            initialZoom: 13.0,
            minZoom: 3.0,
            maxZoom: 19.0,
            onTap: (tapPosition, point) => onMapTap(point),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.route_planner',
            ),
            if (graph != null) ..._buildGraphLayers(),
            if (dijkstraState.path.isNotEmpty && graph != null) _buildPathLayer(),
            _buildMarkerLayer(),
          ],
        ),
        _buildZoomControls(context),
      ],
    );
  }

  List<Widget> _buildGraphLayers() {
    final nodeMarkers = <Marker>[];
    final edges = <Polyline>[];

    for (final nodeId in graph!.getAllNodeIds()) {
      final node = graph!.getNode(nodeId)!;
      final state = dijkstraState.nodeStates[nodeId] ?? NodeVisualState.unvisited;

      nodeMarkers.add(
        Marker(
          point: node.latLng,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getNodeColor(state, nodeId == dijkstraState.currentNode),
              border: Border.all(color: Colors.white, width: 1),
            ),
          ),
        ),
      );

      final neighbors = graph!.getNeighbors(nodeId);
      for (final edge in neighbors) {
        final toNode = graph!.getNode(edge.toNodeId);
        if (toNode != null) {
          edges.add(
            Polyline(
              points: [node.latLng, toNode.latLng],
              strokeWidth: 1,
              color: Colors.grey.withAlpha(100),
            ),
          );
        }
      }
    }

    return [
      PolylineLayer(polylines: edges),
      MarkerLayer(markers: nodeMarkers),
    ];
  }

  Widget _buildPathLayer() {
    if (dijkstraState.path.isEmpty) return const SizedBox.shrink();

    final pathPoints = dijkstraState.path
        .map((nodeId) => graph!.getNode(nodeId)?.latLng)
        .where((point) => point != null)
        .cast<LatLng>()
        .toList();

    return PolylineLayer(
      polylines: [
        Polyline(
          points: pathPoints,
          strokeWidth: 4,
          color: Colors.blue,
        ),
      ],
    );
  }

  Widget _buildMarkerLayer() {
    final markers = <Marker>[];

    if (startPoint != null) {
      markers.add(
        Marker(
          point: startPoint!,
          child: const Icon(
            Icons.play_arrow,
            color: Colors.green,
            size: 30,
          ),
        ),
      );
    }

    if (endPoint != null) {
      markers.add(
        Marker(
          point: endPoint!,
          child: const Icon(
            Icons.flag,
            color: Colors.red,
            size: 30,
          ),
        ),
      );
    }

    return MarkerLayer(markers: markers);
  }

  Widget _buildZoomControls(BuildContext context) {
    return Positioned(
      right: 16,
      top: 16,
      child: Column(
        children: [
          FloatingActionButton(
            heroTag: "zoom_in",
            mini: true,
            onPressed: () {
              final currentZoom = mapController.camera.zoom;
              mapController.move(
                mapController.camera.center,
                (currentZoom + 1).clamp(3.0, 19.0),
              );
            },
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: "zoom_out",
            mini: true,
            onPressed: () {
              final currentZoom = mapController.camera.zoom;
              mapController.move(
                mapController.camera.center,
                (currentZoom - 1).clamp(3.0, 19.0),
              );
            },
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            child: const Icon(Icons.remove),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: "fit_bounds",
            mini: true,
            onPressed: () {
              _fitMapToBounds();
            },
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            child: const Icon(Icons.fit_screen),
          ),
        ],
      ),
    );
  }

  void _fitMapToBounds() {
    if (startPoint != null && endPoint != null) {
      // Fit to show both start and end points
      final bounds = _calculateBounds(startPoint!, endPoint!);
      final center = LatLng(
        (bounds.north + bounds.south) / 2,
        (bounds.east + bounds.west) / 2,
      );

      // Calculate appropriate zoom level based on the distance
      final distance = const Distance().as(LengthUnit.Kilometer, startPoint!, endPoint!);
      double zoom;
      if (distance > 50) {
        zoom = 10.0;
      } else if (distance > 10) {
        zoom = 12.0;
      } else if (distance > 5) {
        zoom = 14.0;
      } else {
        zoom = 15.0;
      }

      mapController.move(center, zoom);
    } else if (startPoint != null) {
      // Center on start point
      mapController.move(startPoint!, 15.0);
    } else if (endPoint != null) {
      // Center on end point
      mapController.move(endPoint!, 15.0);
    } else {
      // Default to Brasília
      mapController.move(const LatLng(-15.7942, -47.8822), 13.0);
    }
  }

  ({double north, double south, double east, double west}) _calculateBounds(LatLng point1, LatLng point2) {
    return (
      north: [point1.latitude, point2.latitude].reduce((a, b) => a > b ? a : b),
      south: [point1.latitude, point2.latitude].reduce((a, b) => a < b ? a : b),
      east: [point1.longitude, point2.longitude].reduce((a, b) => a > b ? a : b),
      west: [point1.longitude, point2.longitude].reduce((a, b) => a < b ? a : b),
    );
  }

  Color _getNodeColor(NodeVisualState state, bool isCurrent) {
    if (isCurrent) {
      return Colors.orange;
    }

    switch (state) {
      case NodeVisualState.unvisited:
        return Colors.grey;
      case NodeVisualState.inQueue:
        return Colors.yellow;
      case NodeVisualState.processing:
        return Colors.orange;
      case NodeVisualState.visited:
        return Colors.lightBlue;
      case NodeVisualState.inPath:
        return Colors.blue;
    }
  }
}