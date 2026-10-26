// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'amount.dart';

part 'repayment_input_request.g.dart';

/// A repayment to add or to change. It is in the debt's currency; a `currency` here is `400 read_only`.
///
/// The debt is in the context (``debt``): its currency reads the amount.
@JsonSerializable()
class RepaymentInputRequest {
  const RepaymentInputRequest({required this.amount, required this.date});

  factory RepaymentInputRequest.fromJson(Map<String, Object?> json) =>
      _$RepaymentInputRequestFromJson(json);

  /// In the currency of the debt, greater than 0 and not more than what remains (`400 exceeds_remaining`, which also carries `remaining`).
  final Amount amount;

  /// A calendar day, 2000-01-01 to 2099-12-31. Not before the debt's `start_date` (`400 repayment_before_start`).
  final DateTime date;

  Map<String, Object?> toJson() => _$RepaymentInputRequestToJson(this);
}
