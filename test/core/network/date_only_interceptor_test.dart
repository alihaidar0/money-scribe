import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/network/date_only_interceptor.dart';

import '../../support/fake_http_adapter.dart';

void main() {
  late FakeHttpAdapter server;
  late Dio dio;

  setUp(() {
    server = FakeHttpAdapter((_) => jsonBody(200));
    dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..interceptors.add(const DateOnlyInterceptor())
      ..httpClientAdapter = server;
  });

  test('cuts the midnight of a query day to the day', () async {
    await dio.get<Object?>(
      '/x',
      queryParameters: {
        'date_from': DateTime(2026, 10).toIso8601String(),
        'date_to': DateTime.utc(2026, 10, 31).toIso8601String(),
        'search': 'shop',
        'limit': 50,
      },
    );

    final query = server.requests.single.queryParameters;
    expect(query['date_from'], '2026-10-01');
    expect(query['date_to'], '2026-10-31');
    expect(query['search'], 'shop');
    expect(query['limit'], 50);
  });

  test('cuts the midnight of a body day, at any depth', () async {
    await dio.post<Object?>(
      '/x',
      data: <String, dynamic>{
        'date': DateTime(2026, 10, 24).toIso8601String(),
        'note': 'Weekly shop',
        'nested': {
          'days': [DateTime(2026, 11, 2).toIso8601String(), 3],
        },
      },
    );

    expect(server.requests.single.data, {
      'date': '2026-10-24',
      'note': 'Weekly shop',
      'nested': {
        'days': ['2026-11-02', 3],
      },
    });
  });

  test('leaves a time of day, and any other text, alone', () async {
    await dio.post<Object?>(
      '/x',
      data: <String, dynamic>{
        'at': '2026-10-24T08:30:00.000Z',
        'midnightInText': 'on 2026-10-24T00:00:00.000 sharp',
        'name': '2026-10-24',
      },
    );

    expect(server.requests.single.data, {
      'at': '2026-10-24T08:30:00.000Z',
      'midnightInText': 'on 2026-10-24T00:00:00.000 sharp',
      'name': '2026-10-24',
    });
  });
}
