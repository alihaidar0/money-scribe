import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:money_scribe/features/notifications/domain/notification_permission.dart';
import 'package:money_scribe/features/notifications/domain/push_messaging_repository.dart';

/// Push notifications through Firebase Cloud Messaging.
class FirebasePushMessagingRepository implements PushMessagingRepository {
  const new(this._messaging);

  final FirebaseMessaging _messaging;

  @override
  bool get isAvailable => true;

  @override
  Future<NotificationPermission> permission() async {
    final settings = await _messaging.getNotificationSettings();
    return permissionFor(settings.authorizationStatus);
  }

  @override
  Future<NotificationPermission> requestPermission() async {
    final settings = await _messaging.requestPermission();
    return permissionFor(settings.authorizationStatus);
  }

  // `getToken` and `deleteToken` are deprecated in firebase_messaging 17 in
  // favour of `register()` and `unregister()`, which work with the Firebase
  // installation ID instead of the FCM token. The backend and the Firebase
  // console still address a device by its FCM token, so the move waits for
  // the push endpoints (`docs/backend-api.md`, "The push token and the
  // account"); until then the two calls work as before.
  @override
  // The FCM token is what the backend and the console address, see above.
  // ignore: deprecated_member_use
  Future<String?> token() => _messaging.getToken();

  @override
  // The same: the FCM token is what has to stop working, see above.
  // ignore: deprecated_member_use
  Future<void> forgetToken() => _messaging.deleteToken();

  @visibleForTesting
  static NotificationPermission permissionFor(AuthorizationStatus status) {
    return switch (status) {
      AuthorizationStatus.authorized ||
      AuthorizationStatus.provisional => NotificationPermission.granted,
      AuthorizationStatus.notDetermined ||
      AuthorizationStatus.denied => NotificationPermission.notGranted,
      AuthorizationStatus.deniedPermanently => NotificationPermission.blocked,
    };
  }
}
