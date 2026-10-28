// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'amount.dart';
import 'currency_enum.dart';
import 'debt_line.dart';

part 'currency_debts.g.dart';

@JsonSerializable()
class CurrencyDebts {
  const CurrencyDebts({
    required this.currency,
    required this.owedToYou,
    required this.youOwe,
    required this.overdue,
    required this.open,
  });

  factory CurrencyDebts.fromJson(Map<String, Object?> json) =>
      _$CurrencyDebtsFromJson(json);

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

  /// The `remaining` of the unsettled debts the person lent.
  @JsonKey(name: 'owed_to_you')
  final Amount owedToYou;

  /// The `remaining` of the unsettled debts the person borrowed.
  @JsonKey(name: 'you_owe')
  final Amount youOwe;

  /// By `due_date`, the oldest first; ties by `id`.
  final List<DebtLine> overdue;

  /// By `due_date`, the debts with none last; ties by `id`.
  final List<DebtLine> open;

  Map<String, Object?> toJson() => _$CurrencyDebtsToJson(this);
}
