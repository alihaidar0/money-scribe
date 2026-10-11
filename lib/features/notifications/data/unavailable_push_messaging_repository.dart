import 'package:money_scribe/features/notifications/domain/notification_permission.dart';
import 'package:money_scribe/features/notifications/domain/push_messaging_repository.dart';

/// Stands in where push is not set up: the screens hide the notification
/// settings and nothing is ever asked or sent.
class UnavailablePushMessagingRepository implements PushMessagingRepository {
  const new();

  @override
  bool get isAvailable => false;

  @override
  Future<NotificationPermission> permission() async {
    return NotificationPermission.notGranted;
  }

  @override
  Future<NotificationPermission> requestPermission() async {
    return NotificationPermission.notGranted;
  }

  @override
  Future<String?> token() async => null;
}
