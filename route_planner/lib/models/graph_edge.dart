class GraphEdge {
  final int fromNodeId;
  final int toNodeId;
  final double distance;
  final double travelTime;
  final String roadType;

  const GraphEdge({
    required this.fromNodeId,
    required this.toNodeId,
    required this.distance,
    required this.travelTime,
    required this.roadType,
  });

  double getWeight(String criteria) {
    switch (criteria) {
      case 'distance':
        return distance;
      case 'time':
        return travelTime;
      case 'highway_priority':
        return _getHighwayWeight() + distance * 0.1;
      default:
        return distance;
    }
  }

  double _getHighwayWeight() {
    switch (roadType) {
      case 'motorway':
        return 1.0;
      case 'trunk':
        return 2.0;
      case 'primary':
        return 3.0;
      case 'secondary':
        return 4.0;
      case 'tertiary':
        return 5.0;
      case 'residential':
        return 6.0;
      case 'footway':
      case 'pedestrian':
        return 10.0;
      default:
        return 5.0;
    }
  }

  @override
  String toString() => 'Edge($fromNodeId -> $toNodeId, ${distance.toStringAsFixed(2)}km, ${travelTime.toStringAsFixed(1)}min)';
}