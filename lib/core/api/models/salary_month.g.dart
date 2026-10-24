// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'salary_month.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SalaryMonth _$SalaryMonthFromJson(Map<String, dynamic> json) => SalaryMonth(
  id: json['id'] as String,
  month: json['month'] as String,
  currency: CurrencyEnum.fromJson(json['currency'] as String),
  baseSalary: json['base_salary'] as Amount,
  foodPerDay: json['food_per_day'] as Amount,
  workingDaysInMonth: (json['working_days_in_month'] as num).toInt(),
  workingHoursInMonth: (json['working_hours_in_month'] as num).toInt(),
  extraHoursHundredths: (json['extra_hours_hundredths'] as num).toInt(),
  taxRateBasisPoints: (json['tax_rate_basis_points'] as num).toInt(),
  paymentMode: PaymentModeEnum.fromJson(json['payment_mode'] as String),
  workingDaysFirstHalf: (json['working_days_first_half'] as num?)?.toInt(),
  firstPayDay: (json['first_pay_day'] as num).toInt(),
  secondPayDay: (json['second_pay_day'] as num).toInt(),
  calculationVersion: (json['calculation_version'] as num).toInt(),
  results: Results.fromJson(json['results'] as Map<String, dynamic>),
  payments: (json['payments'] as List<dynamic>)
      .map((e) => Payment.fromJson(e as Map<String, dynamic>))
      .toList(),
  fixedItems: (json['fixed_items'] as List<dynamic>)
      .map((e) => FixedItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  fixedTotals: FixedTotals.fromJson(
    json['fixed_totals'] as Map<String, dynamic>,
  ),
  balances: Balances.fromJson(json['balances'] as Map<String, dynamic>),
  version: (json['version'] as num).toInt(),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$SalaryMonthToJson(SalaryMonth instance) =>
    <String, dynamic>{
      'id': instance.id,
      'month': instance.month,
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
      'calculation_version': instance.calculationVersion,
      'results': instance.results,
      'payments': instance.payments,
      'fixed_items': instance.fixedItems,
      'fixed_totals': instance.fixedTotals,
      'balances': instance.balances,
      'version': instance.version,
      'created_at': instance.createdAt.toIso8601String(),
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
