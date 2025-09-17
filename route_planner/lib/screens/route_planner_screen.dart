import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/osm_service.dart';
import '../models/route_graph.dart';
import '../algorithms/dijkstra_algorithm.dart';
import '../widgets/map_widget.dart';
import '../widgets/algorithm_controls.dart';
import '../widgets/route_info_panel.dart';

class RoutePlannerScreen extends StatefulWidget {
  const RoutePlannerScreen({super.key});

  @override
  State<RoutePlannerScreen> createState() => _RoutePlannerScreenState();
}

class _RoutePlannerScreenState extends State<RoutePlannerScreen> {
  final OSMService _osmService = OSMService();
  final MapController _mapController = MapController();

  RouteGraph? _graph;
  LatLng? _startPoint;
  LatLng? _endPoint;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DijkstraAlgorithm(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Route Planner - Dijkstra Demo'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Consumer<DijkstraAlgorithm>(
          builder: (context, dijkstraAlgorithm, child) {
            return Column(
              children: [
                Expanded(
                  flex: 4,
                  child: Stack(
                    children: [
                      RouteMapWidget(
                        mapController: _mapController,
                        graph: _graph,
                        startPoint: _startPoint,
                        endPoint: _endPoint,
                        dijkstraState: dijkstraAlgorithm.state,
                        onMapTap: _handleMapTap,
                      ),
                      if (_isLoading)
                        Center(
                          child: Card(
                            elevation: 8,
                            color: Colors.blue[50],
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.blue[200]!),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const CircularProgressIndicator(strokeWidth: 3),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Loading Road Network...',
                                    style: TextStyle(
                                      color: Colors.blue[800],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Fetching OpenStreetMap data and\nbuilding the graph structure',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.blue[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      if (_errorMessage != null)
                        Positioned(
                          top: 16,
                          left: 16,
                          right: 16,
                          child: Card(
                            elevation: 8,
                            color: Colors.red[50],
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red[200]!),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          _errorMessage!.contains('No route possible')
                                              ? Icons.warning_amber
                                              : Icons.error_outline,
                                          color: Colors.red[700],
                                          size: 24,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _errorMessage!.contains('No route possible')
                                                ? 'Route Not Found'
                                                : 'Error',
                                            style: TextStyle(
                                              color: Colors.red[700],
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.close, size: 20),
                                          onPressed: () => setState(() => _errorMessage = null),
                                          color: Colors.red[700],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _errorMessage!,
                                      style: TextStyle(
                                        color: Colors.red[800],
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    if (_errorMessage!.contains('No route possible')) ...[
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.blue[50],
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.blue[200]!),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.lightbulb_outline,
                                                 color: Colors.blue[700], size: 16),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Try: Select points closer together, or choose points on the same road network',
                                                style: TextStyle(
                                                  color: Colors.blue[700],
                                                  fontSize: 10,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AlgorithmControls(
                        dijkstraAlgorithm: dijkstraAlgorithm,
                        onFindRoute: () => _findRoute(dijkstraAlgorithm),
                        onReset: () => _reset(dijkstraAlgorithm),
                        canFindRoute: _canFindRoute(),
                      ),
                      Expanded(
                        child: RouteInfoPanel(
                          dijkstraState: dijkstraAlgorithm.state,
                          graph: _graph,
                          startPoint: _startPoint,
                          endPoint: _endPoint,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _handleMapTap(LatLng point) async {
    if (_startPoint == null) {
      setState(() {
        _startPoint = point;
      });
    } else if (_endPoint == null) {
      setState(() {
        _endPoint = point;
      });
      await _loadGraphForRegion();
    } else {
      setState(() {
        _startPoint = point;
        _endPoint = null;
        _graph = null;
      });
    }
  }

  Future<void> _loadGraphForRegion() async {
    if (_startPoint == null || _endPoint == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final bounds = _calculateBounds(_startPoint!, _endPoint!);
      final graph = await _osmService.fetchRoadNetwork(bounds.$1, bounds.$2);

      // Analyze graph connectivity for debugging
      graph.analyzeConnectivity();

      setState(() {
        _graph = graph;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading road data: $e';
        _isLoading = false;
      });
    }
  }

  (LatLng, LatLng) _calculateBounds(LatLng point1, LatLng point2) {
    final minLat = [point1.latitude, point2.latitude].reduce((a, b) => a < b ? a : b);
    final maxLat = [point1.latitude, point2.latitude].reduce((a, b) => a > b ? a : b);
    final minLng = [point1.longitude, point2.longitude].reduce((a, b) => a < b ? a : b);
    final maxLng = [point1.longitude, point2.longitude].reduce((a, b) => a > b ? a : b);

    final latMargin = (maxLat - minLat) * 0.2;
    final lngMargin = (maxLng - minLng) * 0.2;

    return (
      LatLng(minLat - latMargin, minLng - lngMargin),
      LatLng(maxLat + latMargin, maxLng + lngMargin),
    );
  }

  Future<void> _findRoute(DijkstraAlgorithm dijkstraAlgorithm) async {
    if (!_canFindRoute()) return;

    try {
      final startNodeId = await _osmService.findNearestNode(_graph!, _startPoint!);
      final endNodeId = await _osmService.findNearestNode(_graph!, _endPoint!);

      // Check connectivity before running Dijkstra
      print('🔍 Checking graph connectivity...');
      final isConnected = _graph!.isConnected(startNodeId, endNodeId);
      print('🔗 Connectivity result: ${isConnected ? 'CONNECTED' : 'DISCONNECTED'}');

      if (!isConnected) {
        setState(() {
          _errorMessage = 'No route possible: Start and end points are in disconnected parts of the road network. Try selecting closer points or a different area.';
        });
        return;
      }

      await dijkstraAlgorithm.findShortestPath(
        graph: _graph!,
        startNodeId: startNodeId,
        endNodeId: endNodeId,
        animate: true,
        delayMs: 300,
      );

      // Show success message briefly
      if (dijkstraAlgorithm.state.path.isNotEmpty) {
        setState(() {
          _errorMessage = null; // Clear any previous errors
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error finding route: $e';
      });
    }
  }

  void _reset(DijkstraAlgorithm dijkstraAlgorithm) {
    dijkstraAlgorithm.reset();

    setState(() {
      _startPoint = null;
      _endPoint = null;
      _graph = null;
      _errorMessage = null;
    });
  }

  bool _canFindRoute() {
    return _startPoint != null && _endPoint != null && _graph != null && !_isLoading;
  }
}