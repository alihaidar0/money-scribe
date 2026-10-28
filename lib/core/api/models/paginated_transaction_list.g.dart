// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paginated_transaction_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaginatedTransactionList _$PaginatedTransactionListFromJson(
  Map<String, dynamic> json,
) => PaginatedTransactionList(
  next: json['next'] as String?,
  previous: json['previous'] as String?,
  results: (json['results'] as List<dynamic>)
      .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$PaginatedTransactionListToJson(
  PaginatedTransactionList instance,
) => <String, dynamic>{
  'next': instance.next,
  'previous': instance.previous,
  'results': instance.results,
};
