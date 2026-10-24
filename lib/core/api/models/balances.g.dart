// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'balances.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Balances _$BalancesFromJson(Map<String, dynamic> json) => Balances(
  first: json['first'] as SignedAmount,
  second: json['second'] as SignedAmount?,
  month: json['month'] as SignedAmount,
);

Map<String, dynamic> _$BalancesToJson(Balances instance) => <String, dynamic>{
  'first': instance.first,
  'second': instance.second,
  'month': instance.month,
};
