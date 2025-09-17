import 'package:json_annotation/json_annotation.dart';

part 'osm_way.g.dart';

@JsonSerializable()
class OSMWay {
  @JsonKey(name: 'id')
  final int id;

  @JsonKey(name: 'nodes')
  final List<int> nodeIds;

  @JsonKey(name: 'tags')
  final Map<String, dynamic>? tags;

  const OSMWay({
    required this.id,
    required this.nodeIds,
    this.tags,
  });

  String? get highway => tags?['highway'] as String?;
  String? get name => tags?['name'] as String?;
  int? get maxSpeed => int.tryParse(tags?['maxspeed']?.toString() ?? '');
  bool get isOneway => tags?['oneway'] == 'yes';

  double get speedLimit => (maxSpeed ?? _getDefaultSpeedForHighway()).toDouble();

  int _getDefaultSpeedForHighway() {
    switch (highway) {
      case 'motorway':
        return 120;
      case 'trunk':
        return 100;
      case 'primary':
        return 80;
      case 'secondary':
        return 60;
      case 'tertiary':
        return 50;
      case 'residential':
        return 30;
      case 'footway':
      case 'pedestrian':
        return 5;
      default:
        return 50;
    }
  }

  factory OSMWay.fromJson(Map<String, dynamic> json) => _$OSMWayFromJson(json);
  Map<String, dynamic> toJson() => _$OSMWayToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OSMWay &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'OSMWay(id: $id, nodes: ${nodeIds.length}, highway: $highway)';
}