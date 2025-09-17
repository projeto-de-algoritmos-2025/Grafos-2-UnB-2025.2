// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'osm_node.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OSMNode _$OSMNodeFromJson(Map<String, dynamic> json) => OSMNode(
  id: (json['id'] as num).toInt(),
  latitude: (json['lat'] as num).toDouble(),
  longitude: (json['lon'] as num).toDouble(),
  tags: json['tags'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$OSMNodeToJson(OSMNode instance) => <String, dynamic>{
  'id': instance.id,
  'lat': instance.latitude,
  'lon': instance.longitude,
  'tags': instance.tags,
};
