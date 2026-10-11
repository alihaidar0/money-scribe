import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/features/notifications/application/push_messaging_providers.dart';
import 'package:money_scribe/features/notifications/domain/notification_permission.dart';

import '../../../support/fake_push_messaging_repository.dart';

void main() {
  ProviderContainer createContainer(FakePushMessagingRepository repository) {
    final container = ProviderContainer(
      overrides: [
        pushMessagingRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('starts with the permission the device reports', () async {
    final container = createContainer(
      FakePushMessagingRepository(
        currentPermission: NotificationPermission.blocked,
      ),
    );

    expect(
      await container.read(notificationPermissionControllerProvider.future),
      NotificationPermission.blocked,
    );
  });

  test('requesting asks the user once and shows the answer', () async {
    final repository = FakePushMessagingRepository();
    final container = createContainer(repository);
    await container.read(notificationPermissionControllerProvider.future);

    await container
        .read(notificationPermissionControllerProvider.notifier)
        .request();

    expect(repository.requests, 1);
    expect(
      container.read(notificationPermissionControllerProvider).value,
      NotificationPermission.granted,
    );
  });

  test('without a configured repository push stays unavailable', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      container.read(pushMessagingRepositoryProvider).isAvailable,
      isFalse,
    );
  });
}
