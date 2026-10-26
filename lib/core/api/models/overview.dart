// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'currency_enum.dart';
import 'overview_block.dart';

part 'overview.g.dart';

/// The fields every month report has: the month, the currency, and what the month holds in any currency.
@JsonSerializable()
class Overview {
  const Overview({
    required this.month,
    required this.currency,
    required this.hasData,
    required this.currencies,
    required this.total,
    required this.firstPart,
    required this.secondPart,
  });

  factory Overview.fromJson(Map<String, Object?> json) =>
      _$OverviewFromJson(json);

  /// `YYYY-MM`.
  final String month;

  /// The currency of every amount.
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
  @JsonKey(name: 'has_data')
  final bool hasData;

  /// Every currency that has something in the month, ordered by code; the amounts are in `currency` only.
  final List<CurrencyEnum> currencies;

  /// The whole month.
  final OverviewBlock total;

  /// Days 1 to 15; `null` for a month paid once.
  @JsonKey(name: 'first_part')
  final OverviewBlock? firstPart;

  /// Day 16 to the end of the month; `null` for a month paid once.
  @JsonKey(name: 'second_part')
  final OverviewBlock? secondPart;

  Map<String, Object?> toJson() => _$OverviewToJson(this);
}
