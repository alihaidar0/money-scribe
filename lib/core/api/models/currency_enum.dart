// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

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
@JsonEnum()
enum CurrencyEnum {
  @JsonValue('RUB')
  rub('RUB'),
  @JsonValue('USD')
  usd('USD'),
  @JsonValue('EUR')
  eur('EUR'),
  @JsonValue('GBP')
  gbp('GBP'),

  /// The name has been replaced because it contains a keyword. Original name: `TRY`.
  @JsonValue('TRY')
  valueTry('TRY'),
  @JsonValue('SAR')
  sar('SAR'),
  @JsonValue('AED')
  aed('AED'),
  @JsonValue('EGP')
  egp('EGP'),
  @JsonValue('JPY')
  jpy('JPY'),
  @JsonValue('KWD')
  kwd('KWD'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const CurrencyEnum(this.json);

  factory CurrencyEnum.fromJson(String json) =>
      values.firstWhere((e) => e.json == json, orElse: () => $unknown);

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<CurrencyEnum> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
