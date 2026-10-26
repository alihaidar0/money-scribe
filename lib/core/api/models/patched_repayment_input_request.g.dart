// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patched_repayment_input_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PatchedRepaymentInputRequest _$PatchedRepaymentInputRequestFromJson(
  Map<String, dynamic> json,
) => PatchedRepaymentInputRequest(
  amount: json['amount'] as Amount,
  date: DateTime.parse(json['date'] as String),
);

Map<String, dynamic> _$PatchedRepaymentInputRequestToJson(
  PatchedRepaymentInputRequest instance,
) => <String, dynamic>{
  'amount': instance.amount,
  'date': instance.date.toIso8601String(),
};
