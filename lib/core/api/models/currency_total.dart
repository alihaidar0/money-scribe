// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'currency_enum.dart';
import 'signed_amount.dart';

part 'currency_total.g.dart';

@JsonSerializable()
class CurrencyTotal {
  const CurrencyTotal({required this.currency, required this.total});

  factory CurrencyTotal.fromJson(Map<String, Object?> json) =>
      _$CurrencyTotalFromJson(json);

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

  /// Income minus expenses of that day in that currency, with its digits; `-` when it is below zero.
  final SignedAmount total;

  Map<String, Object?> toJson() => _$CurrencyTotalToJson(this);
}
