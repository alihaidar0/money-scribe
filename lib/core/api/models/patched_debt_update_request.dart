// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'amount.dart';

part 'patched_debt_update_request.g.dart';

/// A change to a debt: the fields of the create except `direction` and `currency`, which are `400 read_only`.
@JsonSerializable()
class PatchedDebtUpdateRequest {
  const PatchedDebtUpdateRequest({
    required this.person,
    required this.amount,
    required this.startDate,
    required this.dueDate,
    required this.note,
  });

  factory PatchedDebtUpdateRequest.fromJson(Map<String, Object?> json) =>
      _$PatchedDebtUpdateRequestFromJson(json);

  /// 1 to 50 characters, trimmed.
  final String person;

  /// In the debt's currency. Not below what was repaid (`400 amount_below_repaid`); above it, a settled debt is open again.
  final Amount amount;

  /// A calendar day, 2000-01-01 to 2099-12-31. Not after the date of a repayment (`400 start_after_repayment`).
  @JsonKey(name: 'start_date')
  final DateTime startDate;

  /// A calendar day, 2000-01-01 to 2099-12-31. Not before `start_date`. `null` clears it.
  @JsonKey(name: 'due_date')
  final DateTime? dueDate;

  /// 0 to 100 characters, trimmed. `""` clears it; `null` is `400`.
  final String note;

  Map<String, Object?> toJson() => _$PatchedDebtUpdateRequestToJson(this);
}
