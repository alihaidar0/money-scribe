import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/app/shell/floating_navigation_bar.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/routing/app_routes.dart';
import 'package:money_scribe/core/widgets/skeleton.dart';
import 'package:money_scribe/features/sessions/data/fake/fake_sessions_repository.dart';
import 'package:money_scribe/features/sessions/presentation/sessions_screen.dart';
import 'package:money_scribe/features/settings/domain/app_language.dart';

import '../../../support/fake_ticker.dart';
import '../../../support/open_screen.dart';
import '../../../support/open_sessions.dart';
import '../../../support/refusing_sessions_repository.dart';

Finder sheet(Finder finder) {
  return find.descendant(of: find.byType(BottomSheet), matching: finder);
}

Finder dialog(Finder finder) {
  return find.descendant(of: find.byType(AlertDialog), matching: finder);
}

Future<void> openTab(WidgetTester tester, String label) async {
  await tester.tap(find.widgetWithText(Tab, label));
  await tester.pumpAndSettle();
}

void main() {
  group('opening it from the Settings', () {
    testWidgets('has its row in the Security section', (tester) async {
      await openSettings(tester);

      expect(find.text('Where you are signed in'), findsOneWidget);
      expect(find.text('Security activity'), findsOneWidget);

      await tester.tap(find.text('Where you are signed in'));
      await tester.pumpAndSettle();

      expect(find.byType(SessionsScreen), findsOneWidget);
      expect(find.byType(FloatingNavigationBar), findsNothing);
    });
  });

  group('the Active tab (ST-12)', () {
    testWidgets('has the title, the tabs, and a back arrow', (tester) async {
      await openSessions(tester);

      expect(
        find.widgetWithText(AppBar, 'Where you are signed in'),
        findsOneWidget,
      );
      expect(find.widgetWithText(Tab, 'Active'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Previous'), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);
    });

    testWidgets('lists this device first, marked, and the others', (
      tester,
    ) async {
      await openSessions(tester);

      expect(find.text('Pixel 8'), findsOneWidget);
      expect(find.text('This device'), findsOneWidget);
      expect(find.text('Chrome on Windows'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Pixel 8')).dy,
        lessThan(tester.getTopLeft(find.text('Chrome on Windows')).dy),
      );
    });

    testWidgets('each row says the system, the app, and when it was used', (
      tester,
    ) async {
      await openSessions(tester);

      expect(find.text('Android 15 · Money Scribe 1.4.0+52'), findsOneWidget);
      expect(find.text('Windows 11 · Money Scribe 1.4.0'), findsOneWidget);
      expect(
        find.text('Signed in 20 Oct 2026 · Last active 25 Oct, 18:40'),
        findsOneWidget,
      );
      expect(
        find.text('Signed in 22 Oct 2026 · Last active 24 Oct, 20:15'),
        findsOneWidget,
      );
    });

    testWidgets('has the advice and the button that signs the others out', (
      tester,
    ) async {
      await openSessions(tester);

      expect(
        find.text(
          "If you don't recognise a device, end its session and change your "
          'password.',
        ),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(OutlinedButton, 'Sign out of all other devices'),
        findsOneWidget,
      );
    });

    testWidgets('has no button when this is the only device', (tester) async {
      await openSessions(
        tester,
        settings: const DemoSettings(scenario: DemoScenario.empty),
      );

      expect(find.text('Pixel 8'), findsOneWidget);
      expect(find.text('Sign out of all other devices'), findsNothing);
    });
  });

  group('the details (ST-12c)', () {
    testWidgets('of another device show the facts and offer to end it', (
      tester,
    ) async {
      await openSessions(tester);

      await tester.tap(find.text('Chrome on Windows'));
      await tester.pumpAndSettle();

      expect(sheet(find.text('Chrome on Windows')), findsOneWidget);
      expect(
        sheet(find.text('Windows 11 · Money Scribe 1.4.0')),
        findsOneWidget,
      );
      expect(sheet(find.text('Signed in with')), findsOneWidget);
      expect(sheet(find.text('Password')), findsOneWidget);
      expect(sheet(find.text('22 Oct 2026, 09:30')), findsOneWidget);
      expect(sheet(find.text('24 Oct 2026, 20:15')), findsOneWidget);
      expect(sheet(find.text('20 Jan 2027')), findsOneWidget);
      expect(sheet(find.text('Network (approximate)')), findsOneWidget);
      expect(sheet(find.text('198.51.100.0/24')), findsOneWidget);
      expect(
        sheet(
          find.text(
            'Ending it also turns off fingerprint sign-in on that device.',
          ),
        ),
        findsOneWidget,
      );
      expect(sheet(find.text('End this session')), findsOneWidget);
    });

    testWidgets('of this device cannot be ended there', (tester) async {
      await openSessions(tester);

      await tester.tap(find.text('Pixel 8'));
      await tester.pumpAndSettle();

      expect(sheet(find.text('Fingerprint')), findsOneWidget);
      expect(
        sheet(find.text('This is the device you are using.')),
        findsOneWidget,
      );
      expect(sheet(find.text('End this session')), findsNothing);
    });

    testWidgets('drag down closes the sheet', (tester) async {
      await openSessions(tester);
      await tester.tap(find.text('Chrome on Windows'));
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(200, 40));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsNothing);
    });
  });

  group('ending a session (ST-12d)', () {
    Future<void> endChrome(WidgetTester tester) async {
      await tester.tap(find.text('Chrome on Windows'));
      await tester.pumpAndSettle();
      await tester.tap(sheet(find.text('End this session')));
      await tester.pumpAndSettle();
    }

    testWidgets('asks first, saying what else happens', (tester) async {
      await openSessions(tester);

      await endChrome(tester);

      expect(find.text('End this session?'), findsOneWidget);
      expect(
        find.text(
          'Chrome on Windows will be signed out. Fingerprint sign-in on that '
          'device will be turned off.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('Cancel keeps the session', (tester) async {
      await openSessions(tester);
      await endChrome(tester);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Chrome on Windows'), findsOneWidget);
      expect(find.text('Session ended'), findsNothing);
    });

    testWidgets('End session ends it, says so, and shows the list again', (
      tester,
    ) async {
      await openSessions(tester);
      await endChrome(tester);

      await tester.tap(dialog(find.text('End session')));
      await tester.pumpAndSettle();

      expect(find.text('Session ended'), findsOneWidget);
      expect(find.text('Chrome on Windows'), findsNothing);
      expect(find.text('Sign out of all other devices'), findsNothing);

      // It is among the previous sessions now.
      await openTab(tester, 'Previous');
      expect(find.text('Chrome on Windows'), findsOneWidget);
      expect(find.textContaining('Ended by you'), findsOneWidget);
    });

    testWidgets('a failed end keeps the session and offers Retry', (
      tester,
    ) async {
      final demo = await openSessions(tester);
      await endChrome(tester);
      demo.update(const DemoSettings(save: DemoSave.fails));

      await tester.tap(dialog(find.text('End session')));
      await tester.pumpAndSettle();

      expect(
        find.text("Couldn't end the session. Check your connection."),
        findsOneWidget,
      );
      expect(find.text('Chrome on Windows'), findsOneWidget);

      demo.update(const DemoSettings());
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Chrome on Windows'), findsNothing);
      expect(find.text('Session ended'), findsOneWidget);
    });
  });

  group('signing out the other devices (ST-12e)', () {
    Future<void> openDialog(WidgetTester tester) async {
      await tester.tap(find.text('Sign out of all other devices'));
      await tester.pumpAndSettle();
    }

    testWidgets('asks for the password, saying what happens', (tester) async {
      await openSessions(tester);

      await openDialog(tester);

      expect(find.text('Sign out of all other devices?'), findsOneWidget);
      expect(
        find.text(
          '1 device will be signed out, and fingerprint sign-in will be turned '
          'off on every other phone. You stay signed in here.',
        ),
        findsOneWidget,
      );
      expect(dialog(find.byType(TextField)), findsOneWidget);
    });

    testWidgets('the button waits for a password', (tester) async {
      await openSessions(tester);
      await openDialog(tester);
      final button = find.widgetWithText(FilledButton, 'Sign out others');

      expect(tester.widget<FilledButton>(button).onPressed, isNull);

      await tester.enterText(dialog(find.byType(TextField)), 'secret');
      await tester.pumpAndSettle();

      expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
    });

    testWidgets('signs them out, says how many, and shows the list again', (
      tester,
    ) async {
      await openSessions(tester);
      await openDialog(tester);
      await tester.enterText(dialog(find.byType(TextField)), 'secret');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Sign out others'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('1 device signed out'), findsOneWidget);
      expect(find.text('Chrome on Windows'), findsNothing);
      expect(find.text('Pixel 8'), findsOneWidget);
    });

    testWidgets('Cancel closes it and signs nobody out', (tester) async {
      await openSessions(tester);
      await openDialog(tester);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Chrome on Windows'), findsOneWidget);
    });

    testWidgets(
      'a wrong password is said under the field, and it can be typed again',
      (tester) async {
        await openSessions(
          tester,
          settings: const DemoSettings(signIn: DemoSignIn.wrongPassword),
        );
        await openDialog(tester);
        await tester.enterText(dialog(find.byType(TextField)), 'nope');
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(FilledButton, 'Sign out others'));
        await tester.pumpAndSettle();

        expect(find.text('That password is incorrect.'), findsOneWidget);
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Chrome on Windows'), findsOneWidget);
      },
    );

    testWidgets('too many wrong passwords lock the button with a countdown', (
      tester,
    ) async {
      final ticker = FakeTicker();
      await openSessions(
        tester,
        ticker: ticker,
        sessionsRepository: (demo) => RefusingSessionsRepository(
          demo: demo,
          endOthersFailure: const TooManyRequestsException(
            Duration(minutes: 15),
          ),
        ),
      );
      await openDialog(tester);
      await tester.enterText(dialog(find.byType(TextField)), 'nope');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Sign out others'));
      await tester.pumpAndSettle();

      expect(find.text('Try again in 15:00'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Try again in 15:00'),
            )
            .onPressed,
        isNull,
      );

      ticker.tick(872);
      await tester.pumpAndSettle();
      expect(find.text('Try again in 14:32'), findsOneWidget);

      ticker.tick(0);
      await tester.pumpAndSettle();
      expect(find.text('Sign out others'), findsOneWidget);
    });

    testWidgets('no connection is said under the field', (tester) async {
      await openSessions(
        tester,
        sessionsRepository: (demo) => RefusingSessionsRepository(
          demo: demo,
          endOthersFailure: const NoConnectionException(),
        ),
      );
      await openDialog(tester);
      await tester.enterText(dialog(find.byType(TextField)), 'x');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Sign out others'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          "Couldn't sign out the other devices. Check your connection.",
        ),
        findsOneWidget,
      );
    });
  });

  group('the Previous tab (ST-12b)', () {
    testWidgets('groups the ended sessions under the name of the device', (
      tester,
    ) async {
      await openSessions(tester);

      await openTab(tester, 'Previous');

      expect(
        find.text('Sessions of the last 90 days that have ended.'),
        findsOneWidget,
      );
      // The headings are above their rows.
      expect(
        tester.getTopLeft(find.text('Chrome on Windows')).dy,
        lessThan(tester.getTopLeft(find.text('Pixel 8')).dy),
      );
      expect(find.text('Signed in 12 Oct 2026, 09:30'), findsOneWidget);
      expect(
        find.text('Ended 14 Oct 2026, 20:20 · Password was changed'),
        findsOneWidget,
      );
      expect(find.text('Signed in 2 Sep 2026, 10:00'), findsOneWidget);
      expect(find.text('Ended 2 Oct 2026, 10:00 · Expired'), findsOneWidget);
      expect(find.text('Signed in 5 Oct 2026, 08:10'), findsOneWidget);
      expect(
        find.text('Ended 20 Oct 2026, 08:00 · Signed out'),
        findsOneWidget,
      );
      expect(
        find.text('Previous sessions are kept for 90 days.'),
        findsOneWidget,
      );
    });

    testWidgets('a row opens its details, which cannot be changed', (
      tester,
    ) async {
      await openSessions(tester);
      await openTab(tester, 'Previous');

      await tester.tap(find.text('Signed in 12 Oct 2026, 09:30'));
      await tester.pumpAndSettle();

      expect(sheet(find.text('Chrome on Windows')), findsOneWidget);
      expect(
        sheet(find.text('Ended 14 Oct 2026, 20:20 · Password was changed.')),
        findsOneWidget,
      );
      expect(sheet(find.text('End this session')), findsNothing);
      expect(sheet(find.text('Session ends')), findsNothing);
    });

    testWidgets('the Active tab is still there when going back to it', (
      tester,
    ) async {
      await openSessions(tester);
      await openTab(tester, 'Previous');

      await openTab(tester, 'Active');

      expect(find.text('This device'), findsOneWidget);
    });

    testWidgets('Show more loads the next page', (tester) async {
      await openSessions(
        tester,
        sessionsRepository: (demo) =>
            FakeSessionsRepository(demo: demo, pageSize: 2),
      );
      await openTab(tester, 'Previous');
      expect(find.text('Signed in 2 Sep 2026, 10:00'), findsNothing);

      await tester.tap(find.text('Show more'));
      await tester.pumpAndSettle();

      expect(find.text('Signed in 2 Sep 2026, 10:00'), findsOneWidget);
      expect(find.text('Show more'), findsNothing);
    });

    testWidgets('a page that does not load says so, and can be tried again', (
      tester,
    ) async {
      final demo = await openSessions(
        tester,
        sessionsRepository: (demo) =>
            FakeSessionsRepository(demo: demo, pageSize: 2),
      );
      await openTab(tester, 'Previous');
      demo.update(const DemoSettings(scenario: DemoScenario.noConnection));
      await tester.pumpAndSettle();
      demo.update(const DemoSettings());
      await tester.pumpAndSettle();

      expect(find.text('Show more'), findsOneWidget);
    });
  });

  group('loading, empty, error and no connection (ST-14)', () {
    testWidgets('shows grey blocks while the sessions load', (tester) async {
      final demo = await openSessions(tester);

      demo.update(const DemoSettings(scenario: DemoScenario.loading));
      await tester.tap(find.widgetWithText(Tab, 'Previous'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(SkeletonBox), findsWidgets);

      demo.update(const DemoSettings());
      await tester.pump(const Duration(seconds: 9));
      await tester.pumpAndSettle();
      expect(find.byType(SkeletonBox), findsNothing);
    });

    testWidgets('an error offers Try again', (tester) async {
      final demo = await openSessions(tester);

      demo.update(const DemoSettings(scenario: DemoScenario.error));
      await tester.pumpAndSettle();
      expect(find.text("Couldn't load your devices"), findsOneWidget);

      demo.update(const DemoSettings());
      await tester.pumpAndSettle();
      expect(find.text('Pixel 8'), findsOneWidget);
    });

    testWidgets('no connection offers Try again', (tester) async {
      final demo = await openSessions(tester);

      demo.update(const DemoSettings(scenario: DemoScenario.noConnection));
      await tester.pumpAndSettle();
      expect(find.text('No connection'), findsOneWidget);

      demo.update(const DemoSettings());
      await tester.pumpAndSettle();
      expect(find.text('Pixel 8'), findsOneWidget);
    });

    testWidgets('the Previous tab says when nothing has ended', (tester) async {
      await openSessions(
        tester,
        settings: const DemoSettings(scenario: DemoScenario.empty),
      );

      await openTab(tester, 'Previous');

      expect(find.text('No previous sessions'), findsOneWidget);
    });

    testWidgets('the Previous tab has its own error', (tester) async {
      final demo = await openSessions(tester);
      await openTab(tester, 'Previous');

      demo.update(const DemoSettings(scenario: DemoScenario.error));
      await tester.pumpAndSettle();

      expect(find.text("Couldn't load your devices"), findsOneWidget);
    });
  });

  group('in Arabic', () {
    testWidgets('shows Arabic labels and Western digits', (tester) async {
      await openSessions(tester, language: AppLanguage.arabic);

      expect(find.text('أين سجّلت الدخول'), findsWidgets);
      expect(find.text('النشطة'), findsOneWidget);
      expect(find.text('هذا الجهاز'), findsOneWidget);
      // The brand name stays in Latin letters, the digits are Western.
      expect(find.textContaining('Money Scribe 1.4.0+52'), findsOneWidget);
      expect(find.textContaining('20 '), findsWidgets);
      expect(find.textContaining(RegExp('[٠-٩]')), findsNothing);
    });

    testWidgets('the details and the dialogs are in Arabic', (tester) async {
      await openSessions(tester, language: AppLanguage.arabic);

      await tester.tap(find.text('Chrome on Windows'));
      await tester.pumpAndSettle();
      expect(sheet(find.text('إنهاء هذه الجلسة')), findsOneWidget);

      await tester.tap(sheet(find.text('إنهاء هذه الجلسة')));
      await tester.pumpAndSettle();
      expect(find.text('إنهاء هذه الجلسة؟'), findsOneWidget);
    });
  });

  group('large text', () {
    testWidgets('fits at 200%', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await openSessionsRoute(
        tester,
        AppRoutes.sessions,
        size: const Size(360, 640),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
