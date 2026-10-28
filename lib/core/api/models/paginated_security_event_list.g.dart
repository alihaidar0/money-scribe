// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paginated_security_event_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaginatedSecurityEventList _$PaginatedSecurityEventListFromJson(
  Map<String, dynamic> json,
) => PaginatedSecurityEventList(
  next: json['next'] as String?,
  previous: json['previous'] as String?,
  results: (json['results'] as List<dynamic>)
      .map((e) => SecurityEvent.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$PaginatedSecurityEventListToJson(
  PaginatedSecurityEventList instance,
) => <String, dynamic>{
  'next': instance.next,
  'previous': instance.previous,
  'results': instance.results,
};
