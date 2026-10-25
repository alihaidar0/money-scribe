import 'dart:async';

/// Timers that only fire when the test says so, so no real second passes.
class ManualTimers {
  new();

  final created = <ManualTimer>[];

  /// Creates a timer for [duration]: pass this as the timer factory.
  Timer create(Duration duration, void Function() run) {
    final timer = ManualTimer(duration, run);
    created.add(timer);
    return timer;
  }

  /// The timers that have not fired or been cancelled.
  List<ManualTimer> get active =>
      created.where((timer) => timer.isActive).toList();
}

class ManualTimer implements Timer {
  new(this.duration, this._run);

  final Duration duration;
  final void Function() _run;
  bool _active = true;

  @override
  bool get isActive => _active;

  @override
  int get tick => _active ? 0 : 1;

  /// The time has passed: runs the callback, once.
  void fire() {
    if (!_active) return;
    _active = false;
    _run();
  }

  @override
  void cancel() => _active = false;
}
