// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repayment_input_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RepaymentInputRequest _$RepaymentInputRequestFromJson(
  Map<String, dynamic> json,
) => RepaymentInputRequest(
  amount: json['amount'] as Amount,
  date: DateTime.parse(json['date'] as String),
);

Map<String, dynamic> _$RepaymentInputRequestToJson(
  RepaymentInputRequest instance,
) => <String, dynamic>{
  'amount': instance.amount,
  'date': instance.date.toIso8601String(),
};
