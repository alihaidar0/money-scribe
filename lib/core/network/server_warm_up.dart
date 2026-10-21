import 'package:dio/dio.dart';

/// Nudges a server that may be asleep, so it is awake by the time the person
/// uses the app.
///
/// One request to the health check of the server (`/healthz`): it sends no
/// data and no token, and whatever comes back, or does not, is ignored. Used by
/// staging builds only, where the free server sleeps after 15 minutes without a
/// request; a production server does not sleep.
Future<void> warmUpServer(Dio dio) async {
  try {
    await dio.get<void>(
      '/healthz',
      options: Options(responseType: ResponseType.plain),
    );
  } on DioException {
    // Only a nudge: a failure changes nothing.
  }
}
