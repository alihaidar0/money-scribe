// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repayment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Repayment _$RepaymentFromJson(Map<String, dynamic> json) => Repayment(
  id: json['id'] as String,
  amount: json['amount'] as Amount,
  date: DateTime.parse(json['date'] as String),
  version: (json['version'] as num).toInt(),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$RepaymentToJson(Repayment instance) => <String, dynamic>{
  'id': instance.id,
  'amount': instance.amount,
  'date': instance.date.toIso8601String(),
  'version': instance.version,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};
