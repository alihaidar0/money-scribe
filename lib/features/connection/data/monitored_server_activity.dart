import 'package:money_scribe/core/network/slow_request_monitor.dart';
import 'package:money_scribe/features/connection/domain/server_activity.dart';

/// The server's activity, as seen by the monitor that watches every request.
class MonitoredServerActivity implements ServerActivity {
  const new(this._monitor);

  final SlowRequestMonitor _monitor;

  @override
  bool get isSlow => _monitor.isSlow;

  @override
  Stream<bool> get slowChanges => _monitor.slowChanges;
}
