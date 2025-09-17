// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'osm_way.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OSMWay _$OSMWayFromJson(Map<String, dynamic> json) => OSMWay(
  id: (json['id'] as num).toInt(),
  nodeIds: (json['nodes'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList(),
  tags: json['tags'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$OSMWayToJson(OSMWay instance) => <String, dynamic>{
  'id': instance.id,
  'nodes': instance.nodeIds,
  'tags': instance.tags,
};
