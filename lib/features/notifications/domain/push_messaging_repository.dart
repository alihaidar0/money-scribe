import 'package:money_scribe/features/notifications/domain/notification_permission.dart';

/// Push notifications for this device: the permission to show them and the
/// token that addresses the device.
abstract interface class PushMessagingRepository {
  /// Whether push is set up in this build: not on the web, not on iOS yet, and
  /// not without the Firebase configuration of the flavor.
  bool get isAvailable;

  Future<NotificationPermission> permission();

  /// Asks the user, when the system still allows it, and returns the result.
  Future<NotificationPermission> requestPermission();

  /// The push token of this device, or `null` when there is none.
  Future<String?> token();

  /// Deletes the push token of this device, so nothing addressed to the old
  /// token reaches it any more. Called when the person is signed out; a token
  /// of the next sign-in is a new one. Does nothing where push is unavailable.
  Future<void> forgetToken();
}
