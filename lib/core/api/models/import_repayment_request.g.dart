// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'import_repayment_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ImportRepaymentRequest _$ImportRepaymentRequestFromJson(
  Map<String, dynamic> json,
) => ImportRepaymentRequest(
  date: DateTime.parse(json['date'] as String),
  amount: json['amount'] as Amount,
);

Map<String, dynamic> _$ImportRepaymentRequestToJson(
  ImportRepaymentRequest instance,
) => <String, dynamic>{
  'date': instance.date.toIso8601String(),
  'amount': instance.amount,
};
