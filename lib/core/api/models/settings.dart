// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'currency_enum.dart';
import 'payment_mode_enum.dart';

part 'settings.g.dart';

/// Every setting, with the app's own default for one that was never set.
@JsonSerializable()
class Settings {
  const Settings({
    required this.language,
    required this.timeZone,
    required this.defaultCurrency,
    required this.paymentMode,
    required this.firstPayDay,
    required this.secondPayDay,
    required this.remindOnPayDays,
    required this.version,
    required this.updatedAt,
  });

  factory Settings.fromJson(Map<String, Object?> json) =>
      _$SettingsFromJson(json);

  /// `en` or `ar`.
  final String language;

  /// An IANA name such as `Asia/Riyadh`.
  @JsonKey(name: 'time_zone')
  final String timeZone;

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
  @JsonKey(name: 'default_currency')
  final CurrencyEnum defaultCurrency;
  @JsonKey(name: 'payment_mode')
  final PaymentModeEnum paymentMode;
  @JsonKey(name: 'first_pay_day')
  final int firstPayDay;
  @JsonKey(name: 'second_pay_day')
  final int secondPayDay;
  @JsonKey(name: 'remind_on_pay_days')
  final bool remindOnPayDays;
  final int version;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  Map<String, Object?> toJson() => _$SettingsToJson(this);
}
