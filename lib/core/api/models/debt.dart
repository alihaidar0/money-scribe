// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'amount.dart';
import 'currency_enum.dart';
import 'debt_direction_enum.dart';
import 'debt_status_enum.dart';
import 'repayment.dart';

part 'debt.g.dart';

/// A debt with its repayments and the figures the server derives from them.
///
/// The serializer is given a ``Debt`` and the person's ``today`` (in the context) and writes the derived values.
@JsonSerializable()
class Debt {
  const Debt({
    required this.id,
    required this.direction,
    required this.person,
    required this.amount,
    required this.currency,
    required this.startDate,
    required this.dueDate,
    required this.note,
    required this.repaid,
    required this.remaining,
    required this.status,
    required this.repayments,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Debt.fromJson(Map<String, Object?> json) => _$DebtFromJson(json);

  final String id;
  final DebtDirectionEnum direction;
  final String person;

  /// A decimal string with exactly the number of digits of the currency, such as `12.50`.
  final Amount amount;

  /// The ISO 4217 code of the currency.
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
  @JsonKey(name: 'start_date')
  final DateTime startDate;
  @JsonKey(name: 'due_date')
  final DateTime? dueDate;
  final String note;

  /// The sum of the repayments.
  final Amount repaid;

  /// The amount minus `repaid`, never below 0.
  final Amount remaining;

  /// `settled` when nothing remains; `overdue` when a `due_date` is before the person's day and the debt is not settled; otherwise `open`.
  ///
  /// * `open` - Open.
  /// * `overdue` - Overdue.
  /// * `settled` - Settled.
  final DebtStatusEnum status;

  /// By `date`, then `id`.
  final List<Repayment> repayments;

  /// The `ETag` of every answer whose body is the debt, and the `If-Match` of its change or delete.
  final int version;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  Map<String, Object?> toJson() => _$DebtToJson(this);
}
