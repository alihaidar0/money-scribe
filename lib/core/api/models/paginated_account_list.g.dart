// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paginated_account_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaginatedAccountList _$PaginatedAccountListFromJson(
  Map<String, dynamic> json,
) => PaginatedAccountList(
  next: json['next'] as String?,
  previous: json['previous'] as String?,
  results: (json['results'] as List<dynamic>)
      .map((e) => Account.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$PaginatedAccountListToJson(
  PaginatedAccountList instance,
) => <String, dynamic>{
  'next': instance.next,
  'previous': instance.previous,
  'results': instance.results,
};
