import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/features/notifications/bloc/notifications_bloc.dart';
import 'package:money_scribe/features/notifications/domain/notification_permission.dart';

import '../../../support/fake_push_messaging_repository.dart';
import '../../../support/fake_text_clipboard.dart';

NotificationsBloc _bloc(
  FakePushMessagingRepository pushMessaging, {
  FakeTextClipboard? clipboard,
  bool canCopyPushToken = true,
}) {
  return NotificationsBloc(
    pushMessaging: pushMessaging,
    clipboard: clipboard ?? FakeTextClipboard(),
    canCopyPushToken: canCopyPushToken,
  );
}

void main() {
  group('initial state', () {
    test('is loading where push is available', () {
      final bloc = _bloc(FakePushMessagingRepository());
      addTearDown(bloc.close);

      expect(bloc.state.status, NotificationsStatus.loading);
    });

    test('is unavailable where push is not set up', () {
      final bloc = _bloc(FakePushMessagingRepository(isAvailable: false));
      addTearDown(bloc.close);

      expect(bloc.state.status, NotificationsStatus.unavailable);
    });

    test('keeps whether the push token may be copied', () {
      final allowed = _bloc(FakePushMessagingRepository());
      final refused = _bloc(
        FakePushMessagingRepository(),
        canCopyPushToken: false,
      );
      addTearDown(allowed.close);
      addTearDown(refused.close);

      expect(allowed.state.canCopyPushToken, isTrue);
      expect(refused.state.canCopyPushToken, isFalse);
    });
  });

  group('NotificationsStarted', () {
    blocTest<NotificationsBloc, NotificationsState>(
      'reads the permission the device reports',
      build: () => _bloc(
        FakePushMessagingRepository(
          currentPermission: NotificationPermission.blocked,
        ),
      ),
      act: (bloc) => bloc.add(const NotificationsStarted()),
      expect: () => [
        isA<NotificationsState>()
            .having((s) => s.status, 'status', NotificationsStatus.ready)
            .having(
              (s) => s.permission,
              'permission',
              NotificationPermission.blocked,
            ),
      ],
    );

    blocTest<NotificationsBloc, NotificationsState>(
      'does nothing where push is not available',
      build: () => _bloc(FakePushMessagingRepository(isAvailable: false)),
      act: (bloc) => bloc.add(const NotificationsStarted()),
      expect: () => <NotificationsState>[],
    );

    blocTest<NotificationsBloc, NotificationsState>(
      'reports a failure, and the error, when the permission cannot be read',
      build: () => _bloc(FakePushMessagingRepository(error: Exception('x'))),
      act: (bloc) => bloc.add(const NotificationsStarted()),
      expect: () => [
        isA<NotificationsState>().having(
          (s) => s.status,
          'status',
          NotificationsStatus.failure,
        ),
      ],
      errors: () => [isA<Exception>()],
    );
  });

  group('NotificationPermissionRequested', () {
    late FakePushMessagingRepository pushMessaging;

    setUp(() => pushMessaging = FakePushMessagingRepository());

    blocTest<NotificationsBloc, NotificationsState>(
      'asks the user and shows the answer',
      build: () => _bloc(pushMessaging),
      act: (bloc) => bloc.add(const NotificationPermissionRequested()),
      expect: () => [
        isA<NotificationsState>()
            .having((s) => s.status, 'status', NotificationsStatus.ready)
            .having(
              (s) => s.permission,
              'permission',
              NotificationPermission.granted,
            ),
      ],
      verify: (_) => expect(pushMessaging.requests, 1),
    );

    blocTest<NotificationsBloc, NotificationsState>(
      'asks only once when pressed twice in a row',
      build: () => _bloc(pushMessaging),
      act: (bloc) => bloc
        ..add(const NotificationPermissionRequested())
        ..add(const NotificationPermissionRequested()),
      wait: const Duration(milliseconds: 10),
      verify: (_) => expect(pushMessaging.requests, 1),
    );

    blocTest<NotificationsBloc, NotificationsState>(
      'reports a failure when the request fails',
      build: () => _bloc(FakePushMessagingRepository(error: Exception('x'))),
      act: (bloc) => bloc.add(const NotificationPermissionRequested()),
      expect: () => [
        isA<NotificationsState>().having(
          (s) => s.status,
          'status',
          NotificationsStatus.failure,
        ),
      ],
      errors: () => [isA<Exception>()],
    );
  });

  group('PushTokenCopyRequested', () {
    final copying = isA<NotificationsState>().having(
      (s) => s.tokenCopy,
      'tokenCopy',
      PushTokenCopyStatus.copying,
    );

    PushTokenCopyStatus tokenCopy(NotificationsState state) => state.tokenCopy;

    blocTest<NotificationsBloc, NotificationsState>(
      'copies the token to the clipboard',
      build: () => _bloc(FakePushMessagingRepository(pushToken: 'abc')),
      act: (bloc) => bloc.add(const PushTokenCopyRequested()),
      expect: () => [
        copying,
        isA<NotificationsState>().having(
          tokenCopy,
          'tokenCopy',
          PushTokenCopyStatus.copied,
        ),
      ],
    );

    test('puts the token on the clipboard', () async {
      final clipboard = FakeTextClipboard();
      final bloc = _bloc(
        FakePushMessagingRepository(pushToken: 'abc'),
        clipboard: clipboard,
      );
      addTearDown(bloc.close);

      bloc.add(const PushTokenCopyRequested());
      await bloc.stream.firstWhere(
        (state) => state.tokenCopy == PushTokenCopyStatus.copied,
      );

      expect(clipboard.copied, ['abc']);
    });

    blocTest<NotificationsBloc, NotificationsState>(
      'reports a missing token and copies nothing',
      build: () => _bloc(FakePushMessagingRepository(pushToken: null)),
      act: (bloc) => bloc.add(const PushTokenCopyRequested()),
      expect: () => [
        copying,
        isA<NotificationsState>().having(
          tokenCopy,
          'tokenCopy',
          PushTokenCopyStatus.missing,
        ),
      ],
    );

    blocTest<NotificationsBloc, NotificationsState>(
      'reports a failure, and the error, when reading the token fails',
      build: () => _bloc(FakePushMessagingRepository(error: Exception('x'))),
      act: (bloc) => bloc.add(const PushTokenCopyRequested()),
      expect: () => [
        copying,
        isA<NotificationsState>().having(
          tokenCopy,
          'tokenCopy',
          PushTokenCopyStatus.failure,
        ),
      ],
      errors: () => [isA<Exception>()],
    );

    blocTest<NotificationsBloc, NotificationsState>(
      'is ignored where copying is not allowed',
      build: () =>
          _bloc(FakePushMessagingRepository(), canCopyPushToken: false),
      act: (bloc) => bloc.add(const PushTokenCopyRequested()),
      expect: () => <NotificationsState>[],
    );
  });
}
