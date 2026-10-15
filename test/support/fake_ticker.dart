import 'dart:async';

import 'package:money_scribe/core/time/ticker.dart';

/// A ticker that only moves when the test says so, so no real second passes.
class FakeTicker implements Ticker {
  new();

  final _controllers = <StreamController<int>>[];

  /// The seconds each countdown was started with, in order.
  final started = <int>[];

  @override
  Stream<int> countdown(int seconds) {
    started.add(seconds);
    final controller = StreamController<int>();
    _controllers.add(controller);
    return controller.stream;
  }

  /// Sends [secondsLeft] to the latest countdown. The listener gets it on the
  /// next turn of the event loop: pump, or `pumpEventQueue()`, to deliver it.
  void tick(int secondsLeft) => _controllers.last.add(secondsLeft);
}
