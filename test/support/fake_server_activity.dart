import 'dart:async';

import 'package:money_scribe/features/connection/domain/server_activity.dart';

/// A server whose slowness the test switches by hand.
class FakeServerActivity implements ServerActivity {
  new({this._isSlow = false});

  final _changes = StreamController<bool>.broadcast(sync: true);
  bool _isSlow;

  @override
  bool get isSlow => _isSlow;

  @override
  Stream<bool> get slowChanges => _changes.stream;

  /// The server becomes slow, or stops being.
  void setSlow({required bool value}) {
    if (_isSlow == value) return;
    _isSlow = value;
    _changes.add(value);
  }
}
