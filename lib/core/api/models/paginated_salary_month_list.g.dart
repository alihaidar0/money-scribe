// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paginated_salary_month_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaginatedSalaryMonthList _$PaginatedSalaryMonthListFromJson(
  Map<String, dynamic> json,
) => PaginatedSalaryMonthList(
  next: json['next'] as String?,
  previous: json['previous'] as String?,
  results: (json['results'] as List<dynamic>)
      .map((e) => SalaryMonth.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$PaginatedSalaryMonthListToJson(
  PaginatedSalaryMonthList instance,
) => <String, dynamic>{
  'next': instance.next,
  'previous': instance.previous,
  'results': instance.results,
};
