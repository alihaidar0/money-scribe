// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'currency_enum.dart';
import 'language_enum.dart';
import 'payment_mode_enum.dart';

part 'patched_settings_update_request.g.dart';

/// The settings the person may change. Only the fields sent change; any other field is ``400 read_only``.
@JsonSerializable()
class PatchedSettingsUpdateRequest {
  const PatchedSettingsUpdateRequest({
    required this.language,
    required this.timeZone,
    required this.defaultCurrency,
    required this.paymentMode,
    required this.firstPayDay,
    required this.secondPayDay,
    required this.remindOnPayDays,
  });

  factory PatchedSettingsUpdateRequest.fromJson(Map<String, Object?> json) =>
      _$PatchedSettingsUpdateRequestFromJson(json);

  /// `en` or `ar`; the app sends `en` when the device language is neither.
  ///
  /// * `en` - English.
  /// * `ar` - Arabic.
  final LanguageEnum language;

  /// An IANA name such as `Europe/Moscow`. Leave it out when the device cannot read it.
  @JsonKey(name: 'time_zone')
  final String timeZone;

  /// `null` goes back to "not set": the app's default (`RUB`) applies.
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
  final CurrencyEnum? defaultCurrency;

  /// How the person is paid. `null` goes back to "not set" (`one_payment`).
  ///
  /// * `one_payment` - One payment.
  /// * `two_payments` - Two payments.
  @JsonKey(name: 'payment_mode')
  final PaymentModeEnum? paymentMode;

  /// 1 to 28. `null` goes back to "not set" (20).
  @JsonKey(name: 'first_pay_day')
  final int? firstPayDay;

  /// 1 to 28. `null` goes back to "not set" (5).
  @JsonKey(name: 'second_pay_day')
  final int? secondPayDay;
  @JsonKey(name: 'remind_on_pay_days')
  final bool remindOnPayDays;

  Map<String, Object?> toJson() => _$PatchedSettingsUpdateRequestToJson(this);
}
