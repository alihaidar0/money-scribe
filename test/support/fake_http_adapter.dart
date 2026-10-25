import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// A server that answers with what the test says, so no request leaves the
/// machine. Every request is kept in [requests].
class FakeHttpAdapter implements HttpClientAdapter {
  new(this.handler);

  /// Answers one request: return a [ResponseBody] (see [jsonBody]) or throw a
  /// [DioException] (see [connectionLost]).
  final FutureOr<ResponseBody> Function(RequestOptions options) handler;

  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final body = await handler(options);
    return body;
  }

  @override
  void close({bool force = false}) {}
}

/// A JSON answer with [status], like the server's.
ResponseBody jsonBody(
  int status, [
  Object? body = const <String, Object?>{},
  Map<String, String> headers = const {},
]) {
  return ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
      for (final entry in headers.entries) entry.key: [entry.value],
    },
  );
}

/// The server's error body: `{type, errors: [{code, detail, attr}]}`.
Map<String, Object?> errorBody(
  String code, {
  String type = 'client_error',
  String? attr,
  Map<String, Object?> extra = const {},
}) {
  return {
    'type': type,
    'errors': [
      {'code': code, 'detail': 'Text for developers.', 'attr': attr, ...extra},
    ],
  };
}

/// A request that never got an answer.
DioException connectionLost(RequestOptions options) {
  return DioException.connectionError(
    requestOptions: options,
    reason: 'The connection was lost.',
  );
}

/// A failed call as the generated client throws it, for a refresh that is
/// written as a plain function.
DioException failedCall(
  int status, [
  Object? body = const <String, Object?>{},
  Map<String, String> headers = const {},
]) {
  final options = RequestOptions(path: '/api/v1/auth/refresh/');
  return DioException.badResponse(
    statusCode: status,
    requestOptions: options,
    response: Response<Object?>(
      requestOptions: options,
      statusCode: status,
      data: body,
      headers: Headers.fromMap({
        for (final entry in headers.entries) entry.key: [entry.value],
      }),
    ),
  );
}
