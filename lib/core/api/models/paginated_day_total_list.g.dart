// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paginated_day_total_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaginatedDayTotalList _$PaginatedDayTotalListFromJson(
  Map<String, dynamic> json,
) => PaginatedDayTotalList(
  next: json['next'] as String?,
  previous: json['previous'] as String?,
  results: (json['results'] as List<dynamic>)
      .map((e) => DayTotal.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$PaginatedDayTotalListToJson(
  PaginatedDayTotalList instance,
) => <String, dynamic>{
  'next': instance.next,
  'previous': instance.previous,
  'results': instance.results,
};
