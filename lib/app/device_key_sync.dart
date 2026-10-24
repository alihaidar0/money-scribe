import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:money_scribe/features/auth/domain/auth_repository.dart';
import 'package:money_scribe/features/auth/domain/device_key_repository.dart';

/// Compares the fingerprint key of this phone with the server's list whenever
/// a person signs in, and when the app starts signed in. The server deletes
/// every key when the password is changed or reset, when the email is changed
/// and when the account is deleted, and a key expires after 30 days without
/// use; this is where the phone finds out and lets go of the key.
///
/// A server that cannot be reached leaves the key as it is: the next sign-in
/// asks again.
class DeviceKeySync {
  new({required AuthRepository auth, required this._deviceKeys}) {
    _subscription = auth.signedInChanges
        .where((isSignedIn) => isSignedIn)
        .listen((_) => unawaited(_sync()));
    if (auth.isSignedIn) unawaited(_sync());
  }

  final DeviceKeyRepository _deviceKeys;
  late final StreamSubscription<bool> _subscription;

  Future<void> _sync() async {
    try {
      await _deviceKeys.sync();
    } on Exception catch (error) {
      // The type only: a message could carry an identifier.
      debugPrint('The fingerprint key was not checked: ${error.runtimeType}');
    }
  }

  Future<void> dispose() => _subscription.cancel();
}
