import 'package:json_annotation/json_annotation.dart';
import 'package:latlong2/latlong.dart';

part 'osm_node.g.dart';

@JsonSerializable()
class OSMNode {
  @JsonKey(name: 'id')
  final int id;

  @JsonKey(name: 'lat')
  final double latitude;

  @JsonKey(name: 'lon')
  final double longitude;

  @JsonKey(name: 'tags')
  final Map<String, dynamic>? tags;

  const OSMNode({
    required this.id,
    required this.latitude,
    required this.longitude,
    this.tags,
  });

  LatLng get latLng => LatLng(latitude, longitude);

  factory OSMNode.fromJson(Map<String, dynamic> json) => _$OSMNodeFromJson(json);
  Map<String, dynamic> toJson() => _$OSMNodeToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OSMNode &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'OSMNode(id: $id, lat: $latitude, lon: $longitude)';
}