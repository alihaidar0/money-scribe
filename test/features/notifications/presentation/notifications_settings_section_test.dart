import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/clipboard/text_clipboard.dart';
import 'package:money_scribe/core/environment/app_environment.dart';
import 'package:money_scribe/core/environment/app_environment_scope.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/features/notifications/data/unavailable_push_messaging_repository.dart';
import 'package:money_scribe/features/notifications/domain/notification_permission.dart';
import 'package:money_scribe/features/notifications/domain/push_messaging_repository.dart';
import 'package:money_scribe/features/notifications/presentation/notifications_settings_section.dart';

import '../../../support/fake_push_messaging_repository.dart';
import '../../../support/fake_text_clipboard.dart';

/// Shows the section on its own, as the Settings screen will.
Future<void> _showSection(
  WidgetTester tester, {
  PushMessagingRepository? pushMessaging,
  FakeTextClipboard? clipboard,
  AppEnvironment environment = AppEnvironment.staging,
  Locale locale = const Locale('en'),
}) async {
  await tester.pumpWidget(
    AppEnvironmentScope(
      environment: environment,
      child: MultiRepositoryProvider(
        providers: [
          RepositoryProvider<PushMessagingRepository>.value(
            value: pushMessaging ?? const UnavailablePushMessagingRepository(),
          ),
          RepositoryProvider<TextClipboard>.value(
            value: clipboard ?? FakeTextClipboard(),
          ),
        ],
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: SingleChildScrollView(child: NotificationsSettingsSection()),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows nothing where push is not available', (tester) async {
    await _showSection(tester);

    expect(find.text('Notifications'), findsNothing);
    expect(find.text('Copy push token'), findsNothing);
  });

  testWidgets('offers to allow notifications, asks once and shows the answer', (
    tester,
  ) async {
    final repository = FakePushMessagingRepository();
    await _showSection(tester, pushMessaging: repository);
    expect(find.text('Not allowed yet'), findsOneWidget);

    await tester.tap(find.text('Allow'));
    await tester.pumpAndSettle();

    expect(repository.requests, 1);
    expect(find.text('Allowed'), findsOneWidget);
    expect(find.text('Allow'), findsNothing);
  });

  testWidgets('allowed notifications have nothing left to ask', (tester) async {
    await _showSection(
      tester,
      pushMessaging: FakePushMessagingRepository(
        currentPermission: NotificationPermission.granted,
      ),
    );

    expect(find.text('Allowed'), findsOneWidget);
    expect(find.text('Allow'), findsNothing);
  });

  testWidgets('blocked notifications point to the system settings', (
    tester,
  ) async {
    await _showSection(
      tester,
      pushMessaging: FakePushMessagingRepository(
        currentPermission: NotificationPermission.blocked,
      ),
    );

    expect(
      find.text('Blocked. Turn notifications on in the system settings.'),
      findsOneWidget,
    );
    expect(find.text('Allow'), findsNothing);
  });

  group('push token', () {
    testWidgets('staging copies the token for test messages', (tester) async {
      final clipboard = FakeTextClipboard();
      await _showSection(
        tester,
        pushMessaging: FakePushMessagingRepository(),
        clipboard: clipboard,
      );

      await tester.tap(find.text('Copy push token'));
      await tester.pumpAndSettle();

      expect(clipboard.copied, ['test-token']);
      expect(find.text('Push token copied'), findsOneWidget);
    });

    testWidgets('says so when the device has no token', (tester) async {
      final clipboard = FakeTextClipboard();
      await _showSection(
        tester,
        pushMessaging: FakePushMessagingRepository(pushToken: null),
        clipboard: clipboard,
      );

      await tester.tap(find.text('Copy push token'));
      await tester.pumpAndSettle();

      expect(clipboard.copied, isEmpty);
      expect(find.text('No push token yet'), findsOneWidget);
    });

    testWidgets('production never offers the token', (tester) async {
      await _showSection(
        tester,
        pushMessaging: FakePushMessagingRepository(),
        environment: AppEnvironment.production,
      );

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Copy push token'), findsNothing);
    });
  });

  testWidgets('is translated into Arabic', (tester) async {
    await _showSection(
      tester,
      pushMessaging: FakePushMessagingRepository(),
      locale: const Locale('ar'),
    );

    expect(find.text('الإشعارات'), findsOneWidget);
    expect(find.text('غير مسموح بها بعد'), findsOneWidget);
    expect(find.text('السماح'), findsOneWidget);
  });
}
