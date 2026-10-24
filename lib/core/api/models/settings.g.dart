// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Settings _$SettingsFromJson(Map<String, dynamic> json) => Settings(
  language: json['language'] as String,
  timeZone: json['time_zone'] as String,
  defaultCurrency: CurrencyEnum.fromJson(json['default_currency'] as String),
  paymentMode: PaymentModeEnum.fromJson(json['payment_mode'] as String),
  firstPayDay: (json['first_pay_day'] as num).toInt(),
  secondPayDay: (json['second_pay_day'] as num).toInt(),
  remindOnPayDays: json['remind_on_pay_days'] as bool,
  version: (json['version'] as num).toInt(),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$SettingsToJson(Settings instance) => <String, dynamic>{
  'language': instance.language,
  'time_zone': instance.timeZone,
  'default_currency': _$CurrencyEnumEnumMap[instance.defaultCurrency]!,
  'payment_mode': _$PaymentModeEnumEnumMap[instance.paymentMode]!,
  'first_pay_day': instance.firstPayDay,
  'second_pay_day': instance.secondPayDay,
  'remind_on_pay_days': instance.remindOnPayDays,
  'version': instance.version,
  'updated_at': instance.updatedAt.toIso8601String(),
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
