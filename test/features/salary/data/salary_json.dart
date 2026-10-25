import 'package:dio/dio.dart';
import 'package:money_scribe/core/network/omit_nulls_interceptor.dart';

import '../../../support/fake_http_adapter.dart';

/// A Dio on the invented address of the tests, answered by [adapter], and
/// built the way the app builds its own (`null` fields are left out).
Dio salaryTestDio(FakeHttpAdapter adapter) {
  return Dio(
      BaseOptions(
        baseUrl: 'https://api.example.test',
        contentType: Headers.jsonContentType,
      ),
    )
    ..interceptors.add(const OmitNullsInterceptor())
    ..httpClientAdapter = adapter;
}

/// A fixed item as the server sends it.
Map<String, Object?> fixedItemJson({
  String id = '0192a000-0000-7000-8000-000000000001',
  String name = 'Scholarship',
  String amount = '5000.00',
  String currency = 'RUB',
  String kind = 'income',
  String part = 'first',
  int version = 1,
}) {
  return {
    'id': id,
    'name': name,
    'amount': amount,
    'currency': currency,
    'kind': kind,
    'part': part,
    'version': version,
    'created_at': '2026-10-24T08:00:00Z',
    'updated_at': '2026-10-24T08:00:00Z',
  };
}

/// A saved month as the server sends it: the invented "Case A" of the tests
/// (a base salary of 100,000.00, 10 of 20 days in the first half).
Map<String, Object?> salaryMonthJson({
  String month = '2026-10',
  String currency = 'RUB',
  String paymentMode = 'two_payments',
  int? workingDaysFirstHalf = 10,
  int version = 1,
  List<Map<String, Object?>> fixedItems = const [],
  List<Map<String, Object?>>? payments,
  Map<String, Object?>? balances,
}) {
  final split = paymentMode == 'two_payments';
  return {
    'id': '0192a000-0000-7000-8000-0000000000aa',
    'month': month,
    'currency': currency,
    'base_salary': '100000.00',
    'food_per_day': '500.00',
    'working_days_in_month': 20,
    'working_hours_in_month': 160,
    'extra_hours_hundredths': 800,
    'tax_rate_basis_points': 1300,
    'payment_mode': paymentMode,
    'working_days_first_half': workingDaysFirstHalf,
    'first_pay_day': 20,
    'second_pay_day': 5,
    'calculation_version': 1,
    'results': {
      'food_allowance': '10000.00',
      'extra_hours_pay': '10000.00',
      'income_before_tax': '120000.00',
      'tax': '15600.00',
      'total_after_tax': '104400.00',
    },
    'payments':
        payments ??
        (split
            ? [
                {'part': 'first', 'amount': '43500.00'},
                {'part': 'second', 'amount': '60900.00'},
              ]
            : [
                {'part': 'first', 'amount': '104400.00'},
              ]),
    'fixed_items': fixedItems,
    'fixed_totals': {
      'first': {'income': '0.00', 'expense': '0.00'},
      'second': {'income': '0.00', 'expense': '0.00'},
    },
    'balances':
        balances ??
        (split
            ? {'first': '43500.00', 'second': '60900.00', 'month': '104400.00'}
            : {'first': '104400.00', 'second': null, 'month': '104400.00'}),
    'version': version,
    'created_at': '2026-10-24T08:00:00Z',
    'updated_at': '2026-10-24T08:00:00Z',
  };
}
