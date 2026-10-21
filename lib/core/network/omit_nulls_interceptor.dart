import 'dart:convert';

import 'package:dio/dio.dart';

/// Leaves out every field of a request body that is `null`.
///
/// The generated models write an optional field they do not have as `null`,
/// but the server wants it left out (`"time_zone": null` is an error, no
/// `time_zone` means "unknown"). Nested objects and lists are cleaned too: the
/// body is turned into plain JSON first, which runs the `toJson` of every
/// nested model.
class OmitNullsInterceptor extends Interceptor {
  const new();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final data = options.data;
    if (data is Map<String, dynamic>) {
      final plain = jsonDecode(jsonEncode(data));
      if (plain is Map<String, dynamic>) options.data = withoutNulls(plain);
    }
    handler.next(options);
  }

  /// A copy of [map] without the entries whose value is `null`, at any depth.
  static Map<String, dynamic> withoutNulls(Map<String, dynamic> map) {
    return {
      for (final entry in map.entries)
        if (entry.value != null) entry.key: _clean(entry.value),
    };
  }

  static Object? _clean(Object? value) {
    return switch (value) {
      final Map<String, dynamic> map => withoutNulls(map),
      final List<Object?> list => [
        for (final item in list)
          if (item != null) _clean(item),
      ],
      _ => value,
    };
  }
}
