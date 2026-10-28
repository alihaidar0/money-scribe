// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paginated_session_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaginatedSessionList _$PaginatedSessionListFromJson(
  Map<String, dynamic> json,
) => PaginatedSessionList(
  next: json['next'] as String?,
  previous: json['previous'] as String?,
  results: (json['results'] as List<dynamic>)
      .map((e) => Session.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$PaginatedSessionListToJson(
  PaginatedSessionList instance,
) => <String, dynamic>{
  'next': instance.next,
  'previous': instance.previous,
  'results': instance.results,
};
