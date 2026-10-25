// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patched_settings_update_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PatchedSettingsUpdateRequest _$PatchedSettingsUpdateRequestFromJson(
  Map<String, dynamic> json,
) => PatchedSettingsUpdateRequest(
  language: LanguageEnum.fromJson(json['language'] as String),
  timeZone: json['time_zone'] as String,
  defaultCurrency: json['default_currency'] == null
      ? null
      : CurrencyEnum.fromJson(json['default_currency'] as String),
  paymentMode: json['payment_mode'] == null
      ? null
      : PaymentModeEnum.fromJson(json['payment_mode'] as String),
  firstPayDay: (json['first_pay_day'] as num?)?.toInt(),
  secondPayDay: (json['second_pay_day'] as num?)?.toInt(),
  remindOnPayDays: json['remind_on_pay_days'] as bool,
);

Map<String, dynamic> _$PatchedSettingsUpdateRequestToJson(
  PatchedSettingsUpdateRequest instance,
) => <String, dynamic>{
  'language': _$LanguageEnumEnumMap[instance.language]!,
  'time_zone': instance.timeZone,
  'default_currency': _$CurrencyEnumEnumMap[instance.defaultCurrency],
  'payment_mode': _$PaymentModeEnumEnumMap[instance.paymentMode],
  'first_pay_day': instance.firstPayDay,
  'second_pay_day': instance.secondPayDay,
  'remind_on_pay_days': instance.remindOnPayDays,
};

const _$LanguageEnumEnumMap = {
  LanguageEnum.en: 'en',
  LanguageEnum.ar: 'ar',
  LanguageEnum.$unknown: r'$unknown',
};

const _$CurrencyEnumEnumMap = {
  CurrencyEnum.rub: 'RUB',
  CurrencyEnum.usd: 'USD',
  CurrencyEnum.eur: 'EUR',
  CurrencyEnum.gbp: 'GBP',
  CurrencyEnum.valueTry: 'TRY',
  CurrencyEnum.sar: 'SAR',
  CurrencyEnum.aed: 'AED',
  CurrencyEnum.egp: 'EGP',
  CurrencyEnum.jpy: 'JPY',
  CurrencyEnum.kwd: 'KWD',
  CurrencyEnum.$unknown: r'$unknown',
};

const _$PaymentModeEnumEnumMap = {
  PaymentModeEnum.onePayment: 'one_payment',
  PaymentModeEnum.twoPayments: 'two_payments',
  PaymentModeEnum.$unknown: r'$unknown',
};
