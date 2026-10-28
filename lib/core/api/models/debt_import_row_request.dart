// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'amount.dart';
import 'currency_enum.dart';
import 'debt_direction_enum.dart';
import 'import_repayment_request.dart';

part 'debt_import_row_request.g.dart';

/// A debt of the file, with its repayments as an array.
@JsonSerializable()
class DebtImportRowRequest {
  const DebtImportRowRequest({
    required this.row,
    required this.direction,
    required this.person,
    required this.amount,
    required this.currency,
    required this.startDate,
    this.note = '',
    this.dueDate,
    this.repayments,
  });

  factory DebtImportRowRequest.fromJson(Map<String, Object?> json) =>
      _$DebtImportRowRequestFromJson(json);

  /// The line in the file: a positive whole number, unique in the call.
  final int row;

  /// `lent` is money the person gave, `borrowed` money the person received. Can be corrected later.
  ///
  /// * `lent` - Lent.
  /// * `borrowed` - Borrowed.
  final DebtDirectionEnum direction;

  /// 1 to 50 characters, trimmed.
  final String person;

  /// A decimal string with exactly the number of digits of the currency, such as `12.50`.
  final Amount amount;

  /// Of the debt, and fixed for good.
  ///
  /// * `RUB` - RUB.
  /// * `USD` - USD.
  /// * `EUR` - EUR.
  /// * `GBP` - GBP.
  /// * `TRY` - TRY.
  /// * `SAR` - SAR.
  /// * `AED` - AED.
  /// * `EGP` - EGP.
  /// * `JPY` - JPY.
  /// * `KWD` - KWD.
  final CurrencyEnum currency;

  /// A calendar day, 2000-01-01 to 2099-12-31.
  @JsonKey(name: 'start_date')
  final DateTime startDate;

  /// A calendar day, 2000-01-01 to 2099-12-31. Not before `start_date` (`400 due_before_start`). `null` or left out: no due date.
  @JsonKey(name: 'due_date')
  final DateTime? dueDate;

  /// 0 to 100 characters, trimmed.
  final String note;

  /// `[]` or a left out cell when there are none. Each is at most the amount still owed.
  final List<ImportRepaymentRequest>? repayments;

  Map<String, Object?> toJson() => _$DebtImportRowRequestToJson(this);
}
