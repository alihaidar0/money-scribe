import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/network/omit_nulls_interceptor.dart';

import '../../support/fake_http_adapter.dart';

/// A model that serializes itself, as the generated ones do.
class _Nested {
  const new(this.value);

  final String? value;

  Map<String, Object?> toJson() => {'value': value, 'other': null};
}

void main() {
  late FakeHttpAdapter server;
  late Dio dio;

  setUp(() {
    server = FakeHttpAdapter((options) => jsonBody(200));
    dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = server
      ..interceptors.add(const OmitNullsInterceptor());
  });

  Object? sent() => server.requests.single.data;

  test('leaves out a field that is null', () async {
    await dio.post<void>(
      '/x',
      data: {'email': 'a@b.c', 'time_zone': null, 'language': null},
    );

    expect(sent(), {'email': 'a@b.c'});
  });

  test('keeps values that are empty, zero or false', () async {
    await dio.post<void>(
      '/x',
      data: {'text': '', 'count': 0, 'flag': false, 'list': <Object>[]},
    );

    expect(sent(), {'text': '', 'count': 0, 'flag': false, 'list': <Object>[]});
  });

  test('cleans nested maps and lists', () async {
    await dio.post<void>(
      '/x',
      data: {
        'device': {'id': '1', 'os_version': null},
        'items': [
          {'a': 1, 'b': null},
          null,
          2,
        ],
      },
    );

    expect(sent(), {
      'device': {'id': '1'},
      'items': [
        {'a': 1},
        2,
      ],
    });
  });

  test('cleans a nested model through its own toJson', () async {
    await dio.post<void>(
      '/x',
      data: {'device': const _Nested('Pixel 8'), 'gone': null},
    );

    expect(sent(), {
      'device': {'value': 'Pixel 8'},
    });
  });

  test('leaves a request with no body alone', () async {
    await dio.get<void>('/x');

    expect(sent(), isNull);
  });

  test('leaves a body that is not a map alone', () async {
    await dio.post<void>('/x', data: 'plain text');

    expect(sent(), 'plain text');
  });
}
