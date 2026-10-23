import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:money_scribe/features/auth/domain/auth_repository.dart';
import 'package:money_scribe/features/notifications/domain/push_messaging_repository.dart';

/// Deletes the push token of this device whenever the person is signed out.
///
/// One place covers every way out: signing out, deleting the account, a
/// session the server ended (a password reset or change on another device, a
/// revoked session) and an account that is gone. A signed-out device must not
/// keep a token that an earlier sign-in registered, because the token is what
/// addresses it. Failing to delete it never stops the sign-out: the failure is
/// reported by its type only, and Firebase drops tokens that are not used.
class PushTokenCleanup {
  new({required AuthRepository auth, required this._push}) {
    _subscription = auth.signedInChanges
        .where((isSignedIn) => !isSignedIn)
        .listen((_) => unawaited(_forgetToken()));
  }

  final PushMessagingRepository _push;
  late final StreamSubscription<bool> _subscription;

  Future<void> _forgetToken() async {
    try {
      await _push.forgetToken();
    } on Exception catch (error) {
      // The type only: a message could carry an identifier.
      debugPrint('The push token could not be deleted: ${error.runtimeType}');
    }
  }

  Future<void> dispose() => _subscription.cancel();
}
