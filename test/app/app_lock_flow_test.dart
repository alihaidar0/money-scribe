import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/routing/app_routes.dart';
import 'package:money_scribe/features/auth/data/fake/fake_auth_repository.dart';
import 'package:money_scribe/features/auth/domain/lock_timeout.dart';
import 'package:money_scribe/features/auth/domain/pin_check.dart';
import 'package:money_scribe/features/auth/presentation/app_lock_screen.dart';
import 'package:money_scribe/features/auth/presentation/pin_entry_screen.dart';
import 'package:money_scribe/features/auth/presentation/sign_in_screen.dart';
import 'package:money_scribe/features/debts/presentation/debts_screen.dart';
import 'package:money_scribe/features/overview/presentation/overview_screen.dart';

import '../support/build_app.dart';
import '../support/fake_clock.dart';
import '../support/fake_ticker.dart';
import '../support/instant_app_lock_repository.dart';

late FixedClock _clock;
late FakeTicker _ticker;
late FakeAuthRepository _auth;

/// The app signed in, with the app lock on (a PIN of 1234, and no fingerprint
/// unless [biometrics] says so).
Future<InstantAppLockRepository> _pump(
  WidgetTester tester, {
  bool locked = false,
  bool biometrics = false,
  LockTimeout timeout = LockTimeout.oneMinute,
  Size size = const Size(412, 915),
}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size;
  addTearDown(tester.view.reset);
  final appLock = InstantAppLockRepository(
    pin: '1234',
    biometricsAvailable: biometrics,
  )..currentTimeout = timeout;
  _clock = FixedClock(DateTime(2026, 10, 23, 9));
  _ticker = FakeTicker();
  final demo = DemoController(latency: Duration.zero);
  _auth = FakeAuthRepository(demo: demo, signedIn: true);
  await tester.pumpWidget(
    buildApp(
      demo: demo,
      ticker: _ticker,
      clock: _clock,
      authRepository: _auth,
      appLockRepository: appLock,
      locked: locked,
    ),
  );
  await tester.pumpAndSettle();
  return appLock;
}

Future<void> _typePin(WidgetTester tester, String pin) async {
  for (final digit in pin.split('')) {
    await tester.tap(find.text(digit));
    await tester.pumpAndSettle();
  }
}

Future<void> _leaveAndReturn(WidgetTester tester, Duration away) async {
  tester.binding
    ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
    ..handleAppLifecycleStateChanged(AppLifecycleState.hidden)
    ..handleAppLifecycleStateChanged(AppLifecycleState.paused);
  await tester.pumpAndSettle();
  _clock.time = _clock.time.add(away);
  tester.binding
    ..handleAppLifecycleStateChanged(AppLifecycleState.hidden)
    ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
    ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  await tester.pumpAndSettle();
}

void _go(WidgetTester tester, String path) {
  GoRouter.of(tester.element(find.byType(Scaffold).first)).go(path);
}

void main() {
  group('the app opens locked', () {
    testWidgets('a locked start shows the lock, not the app', (tester) async {
      await _pump(tester, locked: true);

      expect(find.byType(AppLockScreen), findsOneWidget);
      expect(find.byType(OverviewScreen), findsNothing);
    });

    testWidgets('the right PIN opens the app', (tester) async {
      await _pump(tester, locked: true);

      await tester.tap(find.text('Use PIN'));
      await tester.pumpAndSettle();
      expect(find.byType(PinEntryScreen), findsOneWidget);
      await _typePin(tester, '1234');

      expect(find.byType(OverviewScreen), findsOneWidget);
    });

    testWidgets('the fingerprint opens it without a PIN', (tester) async {
      await _pump(tester, locked: true, biometrics: true);

      expect(find.byType(OverviewScreen), findsOneWidget);
    });

    testWidgets('a wrong PIN says so and the app stays shut', (tester) async {
      await _pump(tester, locked: true);
      await tester.tap(find.text('Use PIN'));
      await tester.pumpAndSettle();

      await _typePin(tester, '9999');

      expect(find.text('Incorrect PIN. Try again.'), findsOneWidget);
      expect(find.byType(OverviewScreen), findsNothing);
    });

    testWidgets('no screen of a locked app can be opened by its address', (
      tester,
    ) async {
      await _pump(tester, locked: true);

      _go(tester, AppRoutes.debts);
      await tester.pumpAndSettle();

      expect(find.byType(AppLockScreen), findsOneWidget);
      expect(find.byType(DebtsScreen), findsNothing);
    });
  });

  group('locking after time away', () {
    testWidgets('a short stay in the background keeps the app open', (
      tester,
    ) async {
      await _pump(tester);

      await _leaveAndReturn(tester, const Duration(seconds: 30));

      expect(find.byType(AppLockScreen), findsNothing);
      expect(find.byType(OverviewScreen), findsOneWidget);
    });

    testWidgets(
      'a longer one locks it, and the PIN returns to the same screen',
      (tester) async {
        await _pump(tester);
        _go(tester, AppRoutes.debts);
        await tester.pumpAndSettle();
        expect(find.byType(DebtsScreen), findsOneWidget);

        await _leaveAndReturn(tester, const Duration(minutes: 2));
        expect(find.byType(AppLockScreen), findsOneWidget);
        expect(find.byType(DebtsScreen), findsNothing);

        await tester.tap(find.text('Use PIN'));
        await tester.pumpAndSettle();
        await _typePin(tester, '1234');

        expect(find.byType(DebtsScreen), findsOneWidget);
      },
    );

    testWidgets('with no wait it locks at once', (tester) async {
      await _pump(tester, timeout: LockTimeout.immediately);

      await _leaveAndReturn(tester, const Duration(seconds: 1));

      expect(find.byType(AppLockScreen), findsOneWidget);
    });

    testWidgets('an app with no lock turned on is never locked', (
      tester,
    ) async {
      final appLock = await _pump(tester);
      appLock.pin = null;

      await _leaveAndReturn(tester, const Duration(hours: 5));

      expect(find.byType(AppLockScreen), findsNothing);
    });
  });

  group('wrong PINs', () {
    testWidgets('a pause is counted down, and the pad waits for it', (
      tester,
    ) async {
      final appLock = await _pump(tester, locked: true);
      appLock.queuedChecks.add(const PinWrong(delay: Duration(seconds: 30)));
      await tester.tap(find.text('Use PIN'));
      await tester.pumpAndSettle();

      await _typePin(tester, '9999');

      expect(
        find.text('Too many wrong PINs. Try again in 0:30.'),
        findsOneWidget,
      );
      // Keys do nothing during the pause.
      await _typePin(tester, '1234');
      expect(find.byType(OverviewScreen), findsNothing);

      _ticker.tick(0);
      await tester.pumpAndSettle();
      await _typePin(tester, '1234');
      expect(find.byType(OverviewScreen), findsOneWidget);
    });

    testWidgets('too many sign the person out, and say why', (tester) async {
      final appLock = await _pump(tester, locked: true);
      appLock.queuedChecks.add(const PinTooManyFailures());
      await tester.tap(find.text('Use PIN'));
      await tester.pumpAndSettle();

      await _typePin(tester, '9999');

      expect(find.byType(SignInScreen), findsOneWidget);
      expect(
        find.text('Too many wrong PINs. Sign in with your password.'),
        findsOneWidget,
      );
      expect(_auth.isSignedIn, isFalse);
      // The lock is gone with the session: the next sign-in starts clean.
      expect(appLock.pin, isNull);
    });
  });

  group('the lock in the Settings', () {
    Future<void> openSettings(WidgetTester tester) async {
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
    }

    testWidgets('shows how long the app may stay away, once the lock is on', (
      tester,
    ) async {
      await _pump(tester, size: const Size(412, 1800));

      await openSettings(tester);

      expect(find.text('Lock after'), findsOneWidget);
      expect(find.text('After 1 minute'), findsOneWidget);
    });

    testWidgets('there is no timeout while the lock is off', (tester) async {
      final appLock = await _pump(tester, size: const Size(412, 1800));
      appLock.pin = null;

      await openSettings(tester);

      expect(find.text('Lock after'), findsNothing);
    });

    testWidgets('a new timeout is chosen from the four', (tester) async {
      final appLock = await _pump(tester, size: const Size(412, 1800));
      await openSettings(tester);

      await tester.tap(find.text('Lock after'));
      await tester.pumpAndSettle();
      for (final label in [
        'Immediately',
        'After 30 seconds',
        'After 1 minute',
        'After 5 minutes',
      ]) {
        expect(find.text(label), findsWidgets);
      }
      await tester.tap(find.text('After 5 minutes'));
      await tester.pumpAndSettle();

      expect(appLock.currentTimeout, LockTimeout.fiveMinutes);
      expect(find.text('After 5 minutes'), findsOneWidget);
    });
  });
}
