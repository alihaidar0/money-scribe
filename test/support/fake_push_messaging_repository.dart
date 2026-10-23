import 'package:money_scribe/features/notifications/domain/notification_permission.dart';
import 'package:money_scribe/features/notifications/domain/push_messaging_repository.dart';

/// A push messaging repository with a fixed answer for each call, or with an
/// [error] that every call throws.
class FakePushMessagingRepository implements PushMessagingRepository {
  new({
    this.isAvailable = true,
    this.currentPermission = NotificationPermission.notGranted,
    this.permissionAfterRequest = NotificationPermission.granted,
    this.pushToken = 'test-token',
    this.error,
  });

  @override
  final bool isAvailable;

  NotificationPermission currentPermission;
  final NotificationPermission permissionAfterRequest;
  final String? pushToken;
  final Exception? error;

  /// How many times the user was asked.
  int requests = 0;

  /// How many times the token was deleted.
  int forgotten = 0;

  @override
  Future<NotificationPermission> permission() async {
    _throwIfFailing();
    return currentPermission;
  }

  @override
  Future<NotificationPermission> requestPermission() async {
    // The user takes a moment to answer the system prompt.
    await Future<void>.delayed(Duration.zero);
    _throwIfFailing();
    requests++;
    return currentPermission = permissionAfterRequest;
  }

  @override
  Future<String?> token() async {
    _throwIfFailing();
    return pushToken;
  }

  @override
  Future<void> forgetToken() async {
    forgotten++;
    _throwIfFailing();
  }

  void _throwIfFailing() {
    final failure = error;
    if (failure != null) throw failure;
  }
}
