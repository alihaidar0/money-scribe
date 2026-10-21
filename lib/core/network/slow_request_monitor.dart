import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Starts a timer, injected so tests do not wait for real seconds.
typedef TimerFactory = Timer Function(Duration duration, void Function() run);

/// Notices when the server is slow to answer.
///
/// A request that has waited longer than [threshold] makes the server "slow";
/// it stops being slow when no waiting request is past the threshold. The free
/// staging server sleeps after 15 minutes without a request and the first call
/// afterwards takes about a minute, so the app tells the person to wait.
class SlowRequestMonitor {
  new({this.threshold = defaultThreshold, this._timer = Timer.new});

  /// How long a request may wait before it counts as slow.
  static const defaultThreshold = Duration(seconds: 5);

  final Duration threshold;
  final TimerFactory _timer;
  final _requests = <_Request>{};
  final _changes = StreamController<bool>.broadcast(sync: true);

  bool _isSlow = false;

  /// Whether a request is waiting longer than [threshold].
  bool get isSlow => _isSlow;

  /// Emits `true` when the server becomes slow and `false` when it stops being.
  Stream<bool> get slowChanges => _changes.stream;

  /// A request starts. Call the returned function when it ends, whatever the
  /// way, so it stops counting. Calling it twice does nothing.
  void Function() begin() {
    final request = _Request();
    request.timer = _timer(threshold, () {
      request.isSlow = true;
      _update();
    });
    _requests.add(request);
    return () => _end(request);
  }

  void _end(_Request request) {
    if (!_requests.remove(request)) return;
    request.timer.cancel();
    _update();
  }

  void _update() {
    final slow = _requests.any((request) => request.isSlow);
    if (slow == _isSlow) return;
    _isSlow = slow;
    _changes.add(slow);
  }

  Future<void> dispose() async {
    for (final request in _requests) {
      request.timer.cancel();
    }
    _requests.clear();
    await _changes.close();
  }
}

class _Request {
  late Timer timer;
  bool isSlow = false;
}

/// An HTTP adapter that tells a [SlowRequestMonitor] about every request that
/// goes out through [_inner]. Watching the adapter, below every interceptor,
/// counts each real request once, including the ones sent again after a
/// refresh.
class MonitoredHttpAdapter implements HttpClientAdapter {
  const new(this._inner, this._monitor);

  final HttpClientAdapter _inner;
  final SlowRequestMonitor _monitor;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final end = _monitor.begin();
    try {
      return await _inner.fetch(options, requestStream, cancelFuture);
    } finally {
      end();
    }
  }

  @override
  void close({bool force = false}) => _inner.close(force: force);
}
