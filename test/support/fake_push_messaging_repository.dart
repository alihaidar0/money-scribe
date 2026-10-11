import 'package:money_scribe/features/notifications/domain/notification_permission.dart';
import 'package:money_scribe/features/notifications/domain/push_messaging_repository.dart';

/// A push messaging repository with a fixed answer for each call.
class FakePushMessagingRepository implements PushMessagingRepository {
  new({
    this.isAvailable = true,
    this.currentPermission = NotificationPermission.notGranted,
    this.permissionAfterRequest = NotificationPermission.granted,
    this.pushToken = 'test-token',
  });

  @override
  final bool isAvailable;

  NotificationPermission currentPermission;
  final NotificationPermission permissionAfterRequest;
  final String? pushToken;

  /// How many times the user was asked.
  int requests = 0;

  @override
  Future<NotificationPermission> permission() async => currentPermission;

  @override
  Future<NotificationPermission> requestPermission() async {
    requests++;
    return currentPermission = permissionAfterRequest;
  }

  @override
  Future<String?> token() async => pushToken;
}
