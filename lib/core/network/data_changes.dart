import 'dart:async';

import 'package:dio/dio.dart';

/// Announces that this device saved something on the server, so a screen that
/// shows figures made of it, such as the Overview, loads them again. The server
/// does not push changes, and the app is the only writer on this device.
class DataChanges {
  final _controller = StreamController<void>.broadcast();

  Stream<void> get stream => _controller.stream;

  void notify() {
    if (!_controller.isClosed) _controller.add(null);
  }

  Future<void> dispose() => _controller.close();
}

/// Calls [DataChanges.notify] after every request that changes data and was
/// accepted. Reading never announces a change.
class DataChangesInterceptor extends Interceptor {
  const new(this._changes);

  final DataChanges _changes;

  static const _reads = {'GET', 'HEAD', 'OPTIONS'};

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (!_reads.contains(response.requestOptions.method.toUpperCase())) {
      _changes.notify();
    }
    handler.next(response);
  }
}
