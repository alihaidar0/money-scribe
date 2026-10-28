// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'salary_month_import_row_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SalaryMonthImportRowRequest _$SalaryMonthImportRowRequestFromJson(
  Map<String, dynamic> json,
) => SalaryMonthImportRowRequest(
  row: (json['row'] as num).toInt(),
  month: json['month'] as String,
  currency: CurrencyEnum.fromJson(json['currency'] as String),
  baseSalary: json['base_salary'] as Amount,
  foodPerDay: json['food_per_day'] as Amount,
  workingDaysInMonth: (json['working_days_in_month'] as num).toInt(),
  workingHoursInMonth: (json['working_hours_in_month'] as num).toInt(),
  extraHours: json['extra_hours'] as String,
  taxRate: json['tax_rate'] as String,
  paymentMode: PaymentModeEnum.fromJson(json['payment_mode'] as String),
  firstPayDay: (json['first_pay_day'] as num).toInt(),
  secondPayDay: (json['second_pay_day'] as num).toInt(),
  workingDaysFirstHalf: (json['working_days_first_half'] as num?)?.toInt(),
  fixedItems: (json['fixed_items'] as List<dynamic>?)
      ?.map((e) => ImportFixedItemRequest.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$SalaryMonthImportRowRequestToJson(
  SalaryMonthImportRowRequest instance,
) => <String, dynamic>{
  'row': instance.row,
  'month': instance.month,
  'currency': _$CurrencyEnumEnumMap[instance.currency]!,
  'base_salary': instance.baseSalary,
  'food_per_day': instance.foodPerDay,
  'working_days_in_month': instance.workingDaysInMonth,
  'working_hours_in_month': instance.workingHoursInMonth,
  'extra_hours': instance.extraHours,
  'tax_rate': instance.taxRate,
  'payment_mode': _$PaymentModeEnumEnumMap[instance.paymentMode]!,
  'working_days_first_half': instance.workingDaysFirstHalf,
  'first_pay_day': instance.firstPayDay,
  'second_pay_day': instance.secondPayDay,
  'fixed_items': instance.fixedItems,
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
