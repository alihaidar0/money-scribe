// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paginated_debt_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaginatedDebtList _$PaginatedDebtListFromJson(Map<String, dynamic> json) =>
    PaginatedDebtList(
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: (json['results'] as List<dynamic>)
          .map((e) => Debt.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PaginatedDebtListToJson(PaginatedDebtList instance) =>
    <String, dynamic>{
      'next': instance.next,
      'previous': instance.previous,
      'results': instance.results,
    };
