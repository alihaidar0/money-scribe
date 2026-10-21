import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/network/server_warm_up.dart';

import '../../support/fake_http_adapter.dart';

void main() {
  Dio dioFor(FakeHttpAdapter server) {
    return Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = server;
  }

  test(
    'asks the health check of the server, once, with no body and no token',
    () async {
      final server = FakeHttpAdapter(
        (options) => ResponseBody.fromString('ok', 200),
      );

      await warmUpServer(dioFor(server));

      final request = server.requests.single;
      expect(request.method, 'GET');
      expect(request.path, '/healthz');
      expect(request.data, isNull);
      expect(request.headers['Authorization'], isNull);
    },
  );

  test('reads the plain answer without trying to parse it', () async {
    final server = FakeHttpAdapter(
      (options) => ResponseBody.fromString('ok', 200),
    );

    await expectLater(warmUpServer(dioFor(server)), completes);
  });

  for (final entry in {
    'no connection': (RequestOptions options) => throw connectionLost(options),
    'a server failure': (RequestOptions options) => jsonBody(500),
    'a busy server': (RequestOptions options) => jsonBody(503),
    'a missing page': (RequestOptions options) => jsonBody(404),
  }.entries) {
    test('ignores ${entry.key}', () async {
      final server = FakeHttpAdapter(entry.value);

      await expectLater(warmUpServer(dioFor(server)), completes);
    });
  }
}
