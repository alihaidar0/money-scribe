// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'salary_month_input_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SalaryMonthInputRequest _$SalaryMonthInputRequestFromJson(
  Map<String, dynamic> json,
) => SalaryMonthInputRequest(
  currency: CurrencyEnum.fromJson(json['currency'] as String),
  baseSalary: json['base_salary'] as Amount,
  foodPerDay: json['food_per_day'] as Amount,
  workingDaysInMonth: (json['working_days_in_month'] as num).toInt(),
  workingHoursInMonth: (json['working_hours_in_month'] as num).toInt(),
  extraHoursHundredths: (json['extra_hours_hundredths'] as num).toInt(),
  taxRateBasisPoints: (json['tax_rate_basis_points'] as num).toInt(),
  paymentMode: PaymentModeEnum.fromJson(json['payment_mode'] as String),
  firstPayDay: (json['first_pay_day'] as num).toInt(),
  secondPayDay: (json['second_pay_day'] as num).toInt(),
  workingDaysFirstHalf: (json['working_days_first_half'] as num?)?.toInt(),
);

Map<String, dynamic> _$SalaryMonthInputRequestToJson(
  SalaryMonthInputRequest instance,
) => <String, dynamic>{
  'currency': _$CurrencyEnumEnumMap[instance.currency]!,
  'base_salary': instance.baseSalary,
  'food_per_day': instance.foodPerDay,
  'working_days_in_month': instance.workingDaysInMonth,
  'working_hours_in_month': instance.workingHoursInMonth,
  'extra_hours_hundredths': instance.extraHoursHundredths,
  'tax_rate_basis_points': instance.taxRateBasisPoints,
  'payment_mode': _$PaymentModeEnumEnumMap[instance.paymentMode]!,
  'working_days_first_half': instance.workingDaysFirstHalf,
  'first_pay_day': instance.firstPayDay,
  'second_pay_day': instance.secondPayDay,
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
