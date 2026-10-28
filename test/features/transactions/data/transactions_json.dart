import 'package:dio/dio.dart';
import 'package:money_scribe/core/network/date_only_interceptor.dart';
import 'package:money_scribe/core/network/omit_nulls_interceptor.dart';

import '../../../support/fake_http_adapter.dart';

/// A Dio on the invented address of the tests, answered by [adapter], and
/// built the way the app builds its own (`null` fields are left out).
Dio transactionsTestDio(FakeHttpAdapter adapter) {
  return Dio(
      BaseOptions(
        baseUrl: 'https://api.example.test',
        contentType: Headers.jsonContentType,
      ),
    )
    ..interceptors.addAll(const [OmitNullsInterceptor(), DateOnlyInterceptor()])
    ..httpClientAdapter = adapter;
}

/// An account as the server sends it.
Map<String, Object?> accountJson({
  String id = '0198f2a4-7c3e-7b1d-9a52-3e6f1d0c4b21',
  String name = 'Travel card',
  String kind = 'card',
  int version = 1,
}) {
  return {
    'id': id,
    'name': name,
    'kind': kind,
    'version': version,
    'created_at': '2026-10-26T09:14:05Z',
    'updated_at': '2026-10-26T09:14:05Z',
  };
}

/// A category as the server sends it: a custom one unless a [key] is given.
Map<String, Object?> categoryJson({
  String id = '0198f2a9-1d20-7c44-b6a1-2f8e3c5d7a90',
  String name = 'Pets',
  String icon = 'gifts',
  String kind = 'both',
  String? key,
  int version = 1,
}) {
  return {
    'id': id,
    'name': name,
    'icon': icon,
    'kind': kind,
    'is_custom': key == null,
    'key': key,
    'version': version,
    'created_at': '2026-10-26T09:20:41Z',
    'updated_at': '2026-10-26T09:20:41Z',
  };
}

/// A page of a list in the cursor envelope.
Map<String, Object?> pageJson(
  List<Map<String, Object?>> results, {
  String? next,
}) {
  return {'next': next, 'previous': null, 'results': results};
}

/// A transaction as the server sends it.
Map<String, Object?> transactionJson({
  String id = '0198f2b0-4e5a-7d12-a3c4-6b7e8f9a0c1d',
  String kind = 'expense',
  String amount = '12.50',
  String currency = 'USD',
  String date = '2026-10-24',
  String categoryId = '0198f2a0-0000-7000-8000-000000000001',
  String accountId = '0198f2a4-7c3e-7b1d-9a52-3e6f1d0c4b21',
  String note = 'Weekly shop',
  String? part,
  String? partMonth,
  int version = 1,
}) {
  return {
    'id': id,
    'kind': kind,
    'amount': amount,
    'currency': currency,
    'date': date,
    'category_id': categoryId,
    'account_id': accountId,
    'note': note,
    'part': part,
    'part_month': partMonth,
    'version': version,
    'created_at': '2026-10-25T18:02:11Z',
    'updated_at': '2026-10-25T18:02:11Z',
  };
}

/// One day of the day totals as the server sends it.
Map<String, Object?> dayTotalJson(String date, Map<String, String> totals) {
  return {
    'date': date,
    'totals': [
      for (final entry in totals.entries)
        {'currency': entry.key, 'total': entry.value},
    ],
  };
}
