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

  @override
  Future<String?> token() => _messaging.getToken();

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
