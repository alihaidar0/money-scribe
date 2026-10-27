// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'amount.dart';

part 'import_repayment_request.g.dart';

/// One repayment in the `repayments` cell of a debt.
@JsonSerializable()
class ImportRepaymentRequest {
  const ImportRepaymentRequest({required this.date, required this.amount});

  factory ImportRepaymentRequest.fromJson(Map<String, Object?> json) =>
      _$ImportRepaymentRequestFromJson(json);

  final DateTime date;

  /// A decimal string with exactly the number of digits of the currency, such as `12.50`.
  final Amount amount;

  Map<String, Object?> toJson() => _$ImportRepaymentRequestToJson(this);
}
