// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Payment _$PaymentFromJson(Map<String, dynamic> json) => Payment(
  partValue: PartEnum.fromJson(json['part'] as String),
  amount: json['amount'] as Amount,
);

Map<String, dynamic> _$PaymentToJson(Payment instance) => <String, dynamic>{
  'part': _$PartEnumEnumMap[instance.partValue]!,
  'amount': instance.amount,
};

const _$PartEnumEnumMap = {
  PartEnum.first: 'first',
  PartEnum.second: 'second',
  PartEnum.$unknown: r'$unknown',
};
