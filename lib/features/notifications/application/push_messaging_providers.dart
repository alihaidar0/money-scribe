import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_scribe/features/notifications/data/unavailable_push_messaging_repository.dart';
import 'package:money_scribe/features/notifications/domain/notification_permission.dart';
import 'package:money_scribe/features/notifications/domain/push_messaging_repository.dart';

/// Push notifications of this device. Replaced in `main` once Firebase has
/// started; until then, and in tests, push is unavailable.
final pushMessagingRepositoryProvider = Provider<PushMessagingRepository>(
  (ref) => const UnavailablePushMessagingRepository(),
);

/// The notification permission, asked for from the Settings screen.
class NotificationPermissionController
    extends AsyncNotifier<NotificationPermission> {
  @override
  Future<NotificationPermission> build() {
    return ref.watch(pushMessagingRepositoryProvider).permission();
  }

  /// Asks the user (when the system still allows it) and shows the result.
  Future<void> request() async {
    final repository = ref.read(pushMessagingRepositoryProvider);
    state = await AsyncValue.guard(repository.requestPermission);
  }
}

final notificationPermissionControllerProvider =
    AsyncNotifierProvider<
      NotificationPermissionController,
      NotificationPermission
    >(NotificationPermissionController.new);
