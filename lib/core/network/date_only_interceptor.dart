import 'package:dio/dio.dart';

/// Sends a calendar day as `YYYY-MM-DD`, which is what the server's `date`
/// fields are.
///
/// The generated client has no type for "a day": a field of the contract that
/// is a date is a `DateTime`, and it is written as `2026-10-24T00:00:00.000`,
/// which the server refuses. The app builds every `DateTime` it sends from a
/// calendar day (midnight), never from an instant, so a text that is exactly
/// midnight, with or without the `Z`, is cut to its day. This runs on the
/// query and on the JSON body, at any depth. Any other text is left alone.
class DateOnlyInterceptor extends Interceptor {
  const new();

  static final _midnight = RegExp(r'^(\d{4}-\d{2}-\d{2})T00:00:00(?:\.0+)?Z?$');

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.queryParameters = {
      for (final entry in options.queryParameters.entries)
        entry.key: _convert(entry.value),
    };
    final data = options.data;
    if (data is Map<String, dynamic>) {
      options.data = _convert(data);
    }
    handler.next(options);
  }

  static Object? _convert(Object? value) {
    return switch (value) {
      final String text => _midnight.firstMatch(text)?.group(1) ?? text,
      final Map<String, dynamic> map => {
        for (final entry in map.entries) entry.key: _convert(entry.value),
      },
      final List<Object?> list => [for (final item in list) _convert(item)],
      _ => value,
    };
  }
}
