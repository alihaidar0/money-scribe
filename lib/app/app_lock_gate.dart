import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:money_scribe/core/time/clock.dart';
import 'package:money_scribe/features/auth/domain/app_lock_repository.dart';
import 'package:money_scribe/features/auth/domain/app_lock_session.dart';
import 'package:money_scribe/features/auth/domain/auth_repository.dart';
import 'package:money_scribe/features/auth/domain/lock_timeout.dart';

/// Decides when the app locks, and says whether it is locked now.
///
/// The app is locked at start, and again after it has been in the background
/// for the time the person chose (`LockTimeout`). The router sends a locked
/// app to the lock screen and back to where the person was once it opens.
///
/// Only a real move to the background counts (`hidden`, `paused`): a system
/// dialog, the fingerprint sheet or a permission prompt only make the app
/// `inactive`, and must not lock it. What the lock needs (whether it is on,
/// the timeout) is read when the app leaves the screen, so coming back is
/// decided at once and no frame of the app shows before the lock does.
///
/// Signing out for any reason (the person, the server, too many wrong PINs)
/// turns the lock off and forgets the PIN, so the next person to sign in
/// starts clean.
class AppLockGate with WidgetsBindingObserver implements AppLockSession {
  new({
    required this._auth,
    required this._repository,
    this._clock = const SystemClock(),
    this._locked = false,
  }) {
    _signedIn = _auth.signedInChanges.listen(_onSignedInChanged);
  }

  final AuthRepository _auth;
  final AppLockRepository _repository;
  final Clock _clock;

  final _changes = StreamController<bool>.broadcast(sync: true);
  late final StreamSubscription<bool> _signedIn;

  bool _locked;

  /// When the app left the screen, while it is away.
  DateTime? _leftAt;

  /// What the lock needed the last time the app left the screen.
  bool _enabled = false;
  LockTimeout _timeout = LockTimeout.standard;

  /// Starts watching the app move to and from the background.
  void start() => WidgetsBinding.instance.addObserver(this);

  @override
  bool get isLocked => _locked;

  @override
  Stream<bool> get changes => _changes.stream;

  @override
  void unlock() {
    _leftAt = null;
    _setLocked(value: false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.hidden || AppLifecycleState.paused:
        _onLeft();
      case AppLifecycleState.resumed:
        _onReturned();
      case AppLifecycleState.inactive || AppLifecycleState.detached:
        break;
    }
  }

  void _onLeft() {
    // `hidden` comes first and `paused` after it: the first one counts.
    _leftAt ??= _clock.now();
    unawaited(_readSettings());
  }

  Future<void> _readSettings() async {
    try {
      _enabled = await _repository.isEnabled();
      _timeout = _enabled ? await _repository.timeout() : _timeout;
      // With no wait the app is locked before it comes back, so no frame of it
      // shows when it does.
      if (_leftAt != null && _isDue(Duration.zero)) _setLocked(value: true);
    } on Exception {
      // Without the settings the app stays as it was: locking it by guesswork
      // would lock a person out of an app they never locked.
    }
  }

  void _onReturned() {
    final left = _leftAt;
    _leftAt = null;
    if (left == null) return;
    if (_isDue(_clock.now().difference(left))) _setLocked(value: true);
  }

  /// Whether the time away, [away], is long enough to lock the app.
  bool _isDue(Duration away) {
    return _enabled && _auth.isSignedIn && away >= _timeout.duration;
  }

  void _onSignedInChanged(bool isSignedIn) {
    if (isSignedIn) return;
    _leftAt = null;
    _enabled = false;
    _setLocked(value: false);
    // Nobody is signed in: the PIN and its count are forgotten.
    unawaited(_forget());
  }

  Future<void> _forget() async {
    try {
      await _repository.disable();
    } on Exception {
      // Nothing more can be done here; the lock is off for a signed-out app.
    }
  }

  void _setLocked({required bool value}) {
    if (_locked == value) return;
    _locked = value;
    _changes.add(value);
  }

  /// Stops watching, and lets go of what the gate listens to.
  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    await _signedIn.cancel();
    await _changes.close();
  }
}
