import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/environment/app_environment.dart';
import 'package:money_scribe/features/notifications/domain/notification_permission.dart';
import 'package:money_scribe/features/settings/domain/app_language.dart';

import '../../../support/build_app.dart';
import '../../../support/fake_language_repository.dart';
import '../../../support/fake_push_messaging_repository.dart';
import '../../../support/fake_text_clipboard.dart';

Future<void> _openSettings(
  WidgetTester tester, {
  FakePushMessagingRepository? pushMessaging,
  FakeTextClipboard? clipboard,
  AppEnvironment environment = AppEnvironment.staging,
  AppLanguage language = AppLanguage.english,
}) async {
  await tester.pumpWidget(
    buildApp(
      languageRepository: FakeLanguageRepository(language),
      pushMessaging: pushMessaging,
      clipboard: clipboard,
      environment: environment,
    ),
  );
  await tester.tap(
    find.byTooltip(language == AppLanguage.arabic ? 'الإعدادات' : 'Settings'),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows nothing where push is not available', (tester) async {
    await _openSettings(tester);

    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Notifications'), findsNothing);
    expect(find.text('Copy push token'), findsNothing);
  });

  testWidgets('offers to allow notifications, asks once and shows the answer', (
    tester,
  ) async {
    final repository = FakePushMessagingRepository();
    await _openSettings(tester, pushMessaging: repository);
    expect(find.text('Not allowed yet'), findsOneWidget);

    await tester.tap(find.text('Allow'));
    await tester.pumpAndSettle();

    expect(repository.requests, 1);
    expect(find.text('Allowed'), findsOneWidget);
    expect(find.text('Allow'), findsNothing);
  });

  testWidgets('allowed notifications have nothing left to ask', (tester) async {
    await _openSettings(
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
    await _openSettings(
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
      await _openSettings(
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
      await _openSettings(
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
      await _openSettings(
        tester,
        pushMessaging: FakePushMessagingRepository(),
        environment: AppEnvironment.production,
      );

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Copy push token'), findsNothing);
    });
  });

  testWidgets('is translated into Arabic', (tester) async {
    await _openSettings(
      tester,
      pushMessaging: FakePushMessagingRepository(),
      language: AppLanguage.arabic,
    );

    expect(find.text('الإشعارات'), findsOneWidget);
    expect(find.text('غير مسموح بها بعد'), findsOneWidget);
    expect(find.text('السماح'), findsOneWidget);
  });
}
