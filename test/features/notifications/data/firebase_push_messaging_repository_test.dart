import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/features/notifications/data/firebase_push_messaging_repository.dart';
import 'package:money_scribe/features/notifications/domain/notification_permission.dart';

void main() {
  group('permissionFor', () {
    final expected = {
      AuthorizationStatus.authorized: NotificationPermission.granted,
      AuthorizationStatus.provisional: NotificationPermission.granted,
      AuthorizationStatus.notDetermined: NotificationPermission.notGranted,
      AuthorizationStatus.denied: NotificationPermission.notGranted,
      AuthorizationStatus.deniedPermanently: NotificationPermission.blocked,
    };

    test('covers every authorization status', () {
      expect(expected.keys, unorderedEquals(AuthorizationStatus.values));
    });

    for (final MapEntry(key: status, value: permission) in expected.entries) {
      test('maps ${status.name} to ${permission.name}', () {
        expect(
          FirebasePushMessagingRepository.permissionFor(status),
          permission,
        );
      });
    }
  });
}
