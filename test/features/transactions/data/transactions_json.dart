import 'package:dio/dio.dart';
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
    ..interceptors.add(const OmitNullsInterceptor())
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
