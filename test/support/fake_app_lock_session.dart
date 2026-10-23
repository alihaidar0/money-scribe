import 'dart:async';

import 'package:money_scribe/features/auth/domain/app_lock_session.dart';

/// A lock the test opens and closes, which counts how often it was opened.
class FakeAppLockSession implements AppLockSession {
  new({this._locked = true});

  bool _locked;
  final _changes = StreamController<bool>.broadcast(sync: true);

  /// How many times the app was unlocked.
  int unlocks = 0;

  @override
  bool get isLocked => _locked;

  @override
  Stream<bool> get changes => _changes.stream;

  @override
  void unlock() {
    unlocks++;
    _locked = false;
    _changes.add(false);
  }
}
