// The render check: every screen and state is drawn to a picture in English
// and Arabic, light and dark, into `build/screens/`, to be looked at. The test
// also fails if a screen throws. It takes about three minutes, so
// `flutter test` skips it (`dart_test.yaml`); run it with:
//   flutter test --run-skipped --tags render test/render
@Tags(['render'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/environment/app_environment.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';
import 'package:money_scribe/core/payments/period_scope.dart';
import 'package:money_scribe/core/routing/app_routes.dart';
import 'package:money_scribe/core/widgets/month_chip.dart';
import 'package:money_scribe/core/widgets/pill_segmented_button.dart';
import 'package:money_scribe/features/auth/data/fake/fake_auth_repository.dart';
import 'package:money_scribe/features/auth/data/fake/fake_device_key_repository.dart';
import 'package:money_scribe/features/debts/bloc/debts_bloc.dart';
import 'package:money_scribe/features/reports/bloc/reports_bloc.dart';
import 'package:money_scribe/features/salary/domain/fixed_item.dart';
import 'package:money_scribe/features/settings/domain/app_language.dart';

import '../support/build_app.dart';
import '../support/fake_language_repository.dart';
import '../support/fake_push_messaging_repository.dart';
import '../support/fake_server_activity.dart';
import '../support/instant_app_lock_repository.dart';
import '../support/render_screen.dart';

typedef _Setup = Future<void> Function(
  WidgetTester tester,
  DemoController demo,
);

class _Scene {
  const new(
    this.name,
    this.route, {
    this.signedIn = false,
    this.setup,
    this.size = const Size(412, 915),
    this.serverWaking = false,
    this.sensor = false,
    this.pinPause,
    this.lockOn = false,
    this.fingerprintKey = false,
  });

  final String name;
  final String route;
  final bool signedIn;

  /// The server is slow to answer: the staging note above the screen shows.
  final bool serverWaking;

  /// The device has a fingerprint that does not match (the lock screen then
  /// says so).
  final bool sensor;

  /// A pause after wrong PINs that is running when the PIN screen opens.
  final Duration? pinPause;

  /// The app lock is on (a PIN is saved).
  final bool lockOn;

  /// The phone has the fingerprint key of the sample account, signed out: the
  /// Sign in screen offers the fingerprint.
  final bool fingerprintKey;
  final _Setup? setup;
  final Size size;
}

Future<void> _useScenario(
  WidgetTester tester,
  DemoController demo,
  DemoScenario scenario,
) async {
  demo.update(demo.settings.copyWith(scenario: scenario));
  await tester.pumpAndSettle();
}

Future<void> _useTwoPayments(WidgetTester tester, DemoController demo) async {
  demo.update(demo.settings.copyWith(paymentMode: PaymentMode.twoPayments));
  await tester.pumpAndSettle();
}

Future<void> _typeCode(WidgetTester tester, String code) async {
  await tester.enterText(find.byType(TextField), code);
  await tester.pumpAndSettle();
}

Future<void> _tapPrimary(WidgetTester tester) async {
  await tester.tap(find.byType(FilledButton).first);
  await tester.pumpAndSettle();
}

Future<void> _tapKeys(WidgetTester tester, List<int> digits) async {
  for (final digit in digits) {
    await tester.tap(find.text('$digit'));
    await tester.pumpAndSettle();
  }
}

/// Taps the first (0) or second (1) segment of the payments choice on the
/// Salary screen, scrolling to it first.
Future<void> _tapPaymentSegment(WidgetTester tester, int index) async {
  final segment = find
      .descendant(
        of: find.byType(PillSegmentedButton<PaymentMode>),
        matching: find.byType(Text),
      )
      .at(index);
  await tester.ensureVisible(segment);
  await tester.pumpAndSettle();
  await tester.tap(segment);
  await tester.pumpAndSettle();
}

/// Taps the segment of the Month, Part 1, Part 2 choice at [index] (0 to 2).
Future<void> _tapPartSegment(WidgetTester tester, int index) async {
  await tester.tap(
    find
        .descendant(
          of: find.byType(PillSegmentedButton<PeriodScope>),
          matching: find.byType(Text),
        )
        .at(index),
  );
  await tester.pumpAndSettle();
}

/// Taps the segment of the choice "Part 1 | Part 2" of the fixed items at
/// [index] (0 or 1), not the one in an open sheet.
Future<void> _tapFixedPart(WidgetTester tester, int index) async {
  await tester.tap(
    find
        .descendant(
          of: find.byType(PillSegmentedButton<FixedItemPart>).first,
          matching: find.byType(Text),
        )
        .at(index),
  );
  await tester.pumpAndSettle();
}

Future<void> _openEditSheet(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.edit_outlined).first);
  await tester.pumpAndSettle();
}

Future<void> _tapSaveMonth(WidgetTester tester) async {
  await tester.tap(find.byType(FilledButton).last);
  await tester.pumpAndSettle();
}

/// Taps the segment of the Categories, Month vs month, Debts choice of the
/// Reports at [index] (0 to 2).
Future<void> _tapReportsView(WidgetTester tester, int index) async {
  await tester.tap(
    find
        .descendant(
          of: find.byType(PillSegmentedButton<ReportsView>),
          matching: find.byType(Text),
        )
        .at(index),
  );
  await tester.pumpAndSettle();
}

const _tallPhone = Size(412, 1800);
const _wideWindow = Size(1280, 800);

final _scenes = <_Scene>[
  const _Scene('auth-1-welcome', AppRoutes.welcome),
  const _Scene('auth-2-sign-in', AppRoutes.signIn),
  _Scene(
    'auth-2b-sign-in-wrong-password',
    AppRoutes.signIn,
    setup: (tester, demo) async {
      demo.update(const DemoSettings(signIn: DemoSignIn.wrongPassword));
      await _tapPrimary(tester);
    },
  ),
  _Scene(
    'auth-2e-sign-in-no-account',
    AppRoutes.signIn,
    setup: (tester, demo) async {
      demo.update(const DemoSettings(signIn: DemoSignIn.emailNotRegistered));
      await _tapPrimary(tester);
    },
  ),
  _Scene(
    'auth-2f-sign-in-challenge',
    AppRoutes.signIn,
    setup: (tester, demo) async {
      demo.update(const DemoSettings(signIn: DemoSignIn.challengeRequired));
      await _tapPrimary(tester);
    },
  ),
  _Scene(
    'auth-2g-sign-in-challenge-refused',
    AppRoutes.signIn,
    setup: (tester, demo) async {
      demo.update(const DemoSettings(signIn: DemoSignIn.challengeRejected));
      await _tapPrimary(tester);
      await tester.tap(find.byType(OutlinedButton).last);
      await tester.pumpAndSettle();
    },
  ),
  _Scene(
    'auth-2c-sign-in-locked',
    AppRoutes.signIn,
    setup: (tester, demo) async {
      demo.update(const DemoSettings(signIn: DemoSignIn.locked));
      await _tapPrimary(tester);
    },
  ),
  _Scene(
    'auth-2d-sign-in-busy',
    AppRoutes.signIn,
    setup: (tester, demo) async {
      demo.update(const DemoSettings(signIn: DemoSignIn.unavailable));
      await _tapPrimary(tester);
    },
  ),
  const _Scene(
    'auth-2h-sign-in-fingerprint',
    AppRoutes.signIn,
    fingerprintKey: true,
  ),
  _Scene(
    'auth-2i-sign-in-fingerprint-unavailable',
    AppRoutes.signIn,
    fingerprintKey: true,
    setup: (tester, demo) async {
      demo.update(const DemoSettings(fingerprint: DemoFingerprint.notEnrolled));
      await _tapPrimary(tester);
    },
  ),
  _Scene(
    'auth-2j-sign-in-fingerprint-refused',
    AppRoutes.signIn,
    fingerprintKey: true,
    setup: (tester, demo) async {
      demo.update(
        const DemoSettings(fingerprint: DemoFingerprint.signInRefused),
      );
      await _tapPrimary(tester);
    },
  ),
  _Scene(
    'auth-2k-sign-in-fingerprint-locked',
    AppRoutes.signIn,
    fingerprintKey: true,
    setup: (tester, demo) async {
      demo.update(const DemoSettings(fingerprint: DemoFingerprint.locked));
      await _tapPrimary(tester);
    },
  ),
  const _Scene('err-5-server-starting', AppRoutes.signIn, serverWaking: true),
  const _Scene(
    'err-5b-server-starting-register',
    AppRoutes.register,
    serverWaking: true,
  ),
  _Scene(
    'nc-1-no-connection',
    AppRoutes.signIn,
    setup: (tester, demo) async {
      demo.update(const DemoSettings(scenario: DemoScenario.noConnection));
      await _tapPrimary(tester);
    },
  ),
  _Scene(
    'err-2-something-went-wrong',
    AppRoutes.signIn,
    setup: (tester, demo) async {
      demo.update(const DemoSettings(scenario: DemoScenario.error));
      await _tapPrimary(tester);
    },
  ),
  const _Scene('auth-3-register', AppRoutes.register),
  _Scene(
    'auth-3-register-filled',
    AppRoutes.register,
    setup: (tester, demo) async {
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'Alex');
      await tester.enterText(fields.at(1), 'alex@example.com');
      await tester.enterText(fields.at(2), 'password1');
      await tester.enterText(fields.at(3), 'password1');
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
    },
  ),
  _Scene(
    'auth-3b-register-errors',
    AppRoutes.register,
    setup: (tester, demo) async {
      demo.update(const DemoSettings(registration: DemoRegistration.rejected));
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'Alex');
      await tester.enterText(fields.at(1), 'alex');
      await tester.enterText(fields.at(2), 'short one');
      await tester.enterText(fields.at(3), 'short one');
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await _tapPrimary(tester);
    },
  ),
  _Scene(
    'auth-3c-register-mismatch',
    AppRoutes.register,
    setup: (tester, demo) async {
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'Alex');
      await tester.enterText(fields.at(1), 'alex@example.com');
      await tester.enterText(fields.at(2), 'one passphrase');
      await tester.enterText(fields.at(3), 'another passphrase');
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await _tapPrimary(tester);
    },
  ),
  _Scene(
    'auth-3d-register-wait',
    AppRoutes.register,
    setup: (tester, demo) async {
      demo.update(const DemoSettings(registration: DemoRegistration.tooSoon));
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'Alex');
      await tester.enterText(fields.at(1), 'alex@example.com');
      await tester.enterText(fields.at(2), 'password1');
      await tester.enterText(fields.at(3), 'password1');
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await _tapPrimary(tester);
    },
  ),
  _Scene(
    'auth-3e-register-busy',
    AppRoutes.register,
    setup: (tester, demo) async {
      demo.update(
        const DemoSettings(registration: DemoRegistration.unavailable),
      );
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'Alex');
      await tester.enterText(fields.at(1), 'alex@example.com');
      await tester.enterText(fields.at(2), 'password1');
      await tester.enterText(fields.at(3), 'password1');
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await _tapPrimary(tester);
    },
  ),
  _Scene(
    'auth-4-verify-email',
    AppRoutes.verifyEmail,
    setup: (tester, demo) => _typeCode(tester, '482'),
  ),
  _Scene(
    'auth-4b-verify-wrong',
    AppRoutes.verifyEmail,
    setup: (tester, demo) async {
      demo.update(const DemoSettings(code: DemoCode.wrong));
      await _typeCode(tester, '481729');
    },
  ),
  _Scene(
    'auth-4c-verify-expired',
    AppRoutes.verifyEmail,
    setup: (tester, demo) async {
      demo.update(const DemoSettings(code: DemoCode.expired));
      await _typeCode(tester, '481729');
    },
  ),
  _Scene(
    'auth-4d-verify-dead',
    AppRoutes.verifyEmail,
    setup: (tester, demo) async {
      demo.update(const DemoSettings(code: DemoCode.attemptsExceeded));
      await _typeCode(tester, '481729');
    },
  ),
  _Scene(
    'auth-4e-verify-busy',
    AppRoutes.verifyEmail,
    setup: (tester, demo) async {
      demo.update(const DemoSettings(code: DemoCode.unavailable));
      await _typeCode(tester, '481729');
    },
  ),
  _Scene(
    'auth-4f-verify-from-sign-in',
    AppRoutes.signIn,
    setup: (tester, demo) async {
      demo.update(const DemoSettings(signIn: DemoSignIn.emailNotVerified));
      await tester.enterText(find.byType(TextField).first, 'alex@example.com');
      await _tapPrimary(tester);
    },
  ),
  const _Scene(
    'auth-5-email-verified',
    AppRoutes.emailVerified,
    signedIn: true,
  ),
  const _Scene('auth-6-pay-setup', AppRoutes.paySetup, signedIn: true),
  _Scene(
    'auth-6b-pay-setup-two',
    AppRoutes.paySetup,
    signedIn: true,
    setup: (tester, demo) async {
      await tester.tap(find.byIcon(Icons.radio_button_unchecked));
      await tester.pumpAndSettle();
    },
  ),
  const _Scene('auth-7-forgot-password', AppRoutes.forgotPassword),
  _Scene(
    'auth-7b-forgot-wait',
    AppRoutes.forgotPassword,
    setup: (tester, demo) async {
      await tester.enterText(find.byType(TextField), 'alex@example.com');
      await _tapPrimary(tester);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await _tapPrimary(tester);
    },
  ),
  _Scene(
    'auth-7c-forgot-busy',
    AppRoutes.forgotPassword,
    setup: (tester, demo) async {
      demo.update(const DemoSettings(code: DemoCode.unavailable));
      await tester.enterText(find.byType(TextField), 'alex@example.com');
      await _tapPrimary(tester);
    },
  ),
  _Scene(
    'auth-8-reset-code',
    AppRoutes.resetCode,
    setup: (tester, demo) => _typeCode(tester, '62'),
  ),
  _Scene(
    'auth-8b-reset-wrong',
    AppRoutes.resetCode,
    setup: (tester, demo) async {
      demo.update(const DemoSettings(code: DemoCode.wrong));
      await _typeCode(tester, '620517');
    },
  ),
  _Scene(
    'auth-9-new-password',
    AppRoutes.newPassword,
    setup: (tester, demo) async {
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'secret123');
      await tester.enterText(fields.at(1), 'secret123');
      await tester.pumpAndSettle();
    },
  ),
  _Scene(
    'auth-9b-new-password-refused',
    AppRoutes.newPassword,
    setup: (tester, demo) async {
      demo.update(
        const DemoSettings(passwordReset: DemoPasswordReset.passwordRefused),
      );
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'secret123');
      await tester.enterText(fields.at(1), 'secret123');
      await tester.pumpAndSettle();
      await _tapPrimary(tester);
    },
  ),
  _Scene(
    'auth-9c-new-password-wait',
    AppRoutes.newPassword,
    setup: (tester, demo) async {
      demo.update(const DemoSettings(passwordReset: DemoPasswordReset.tooSoon));
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'secret123');
      await tester.enterText(fields.at(1), 'secret123');
      await tester.pumpAndSettle();
      await _tapPrimary(tester);
    },
  ),
  const _Scene('auth-10-password-changed', AppRoutes.passwordChanged),
  const _Scene('auth-11-app-lock', AppRoutes.appLock),
  const _Scene(
    'auth-11b-app-lock-fingerprint',
    AppRoutes.appLock,
    sensor: true,
  ),
  const _Scene(
    'auth-12b-pin-paused',
    AppRoutes.pinEntry,
    pinPause: Duration(seconds: 30),
  ),
  _Scene(
    'auth-12-pin-entry',
    AppRoutes.pinEntry,
    setup: (tester, demo) => _tapKeys(tester, [3, 7]),
  ),
  _Scene(
    'auth-13-create-pin',
    AppRoutes.createPin,
    signedIn: true,
    setup: (tester, demo) => _tapKeys(tester, [3]),
  ),
  const _Scene(
    'st-1b-settings-app-lock-on',
    AppRoutes.settings,
    signedIn: true,
    lockOn: true,
    sensor: true,
    size: _tallPhone,
  ),
  const _Scene(
    'st-1c-settings-app-lock-off',
    AppRoutes.settings,
    signedIn: true,
    sensor: true,
    size: _tallPhone,
  ),
  const _Scene('ov-1-overview', AppRoutes.overview, signedIn: true),
  _Scene(
    'ov-1b-overview-previous-month',
    AppRoutes.overview,
    signedIn: true,
    setup: (tester, demo) async {
      await tester.tap(find.byIcon(Icons.chevron_left).first);
      await tester.pumpAndSettle();
    },
  ),
  const _Scene(
    'ov-2-overview-two-payments',
    AppRoutes.overview,
    signedIn: true,
    setup: _useTwoPayments,
  ),
  _Scene(
    'ov-2b-overview-first-part',
    AppRoutes.overview,
    signedIn: true,
    setup: (tester, demo) async {
      await _useTwoPayments(tester, demo);
      await tester.tap(
        find
            .descendant(
              of: find.byType(PillSegmentedButton<PeriodScope>),
              matching: find.byType(Text),
            )
            .at(1),
      );
      await tester.pumpAndSettle();
    },
  ),
  _Scene(
    'ov-3-first-launch',
    AppRoutes.overview,
    signedIn: true,
    setup: (tester, demo) => _useScenario(tester, demo, DemoScenario.empty),
  ),
  _Scene(
    'ov-4-choose-debt',
    AppRoutes.overview,
    signedIn: true,
    setup: (tester, demo) async {
      await tester.tap(find.byType(FilledButton).at(1));
      await tester.pumpAndSettle();
    },
  ),
  _Scene(
    'ov-5-loading',
    AppRoutes.overview,
    signedIn: true,
    setup: (tester, demo) async {
      demo.update(const DemoSettings(scenario: DemoScenario.loading));
      await tester.pump(const Duration(milliseconds: 100));
    },
  ),
  _Scene(
    'ov-6-error',
    AppRoutes.overview,
    signedIn: true,
    setup: (tester, demo) => _useScenario(tester, demo, DemoScenario.error),
  ),
  _Scene(
    'ov-7-no-connection',
    AppRoutes.overview,
    signedIn: true,
    setup: (tester, demo) =>
        _useScenario(tester, demo, DemoScenario.noConnection),
  ),
  const _Scene(
    'ov-wide-two-payments',
    AppRoutes.overview,
    signedIn: true,
    size: Size(1280, 800),
    setup: _useTwoPayments,
  ),
  const _Scene('sal-1-salary', AppRoutes.salary, signedIn: true),
  const _Scene(
    'sal-1-salary-all-inputs',
    AppRoutes.salary,
    signedIn: true,
    size: _tallPhone,
  ),
  _Scene(
    'sal-1-field-errors',
    AppRoutes.salary,
    signedIn: true,
    size: _tallPhone,
    setup: (tester, demo) async {
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '0');
      await tester.enterText(fields.at(1), '40');
      await tester.enterText(fields.at(5), '120');
      await tester.pumpAndSettle();
    },
  ),
  const _Scene(
    'sal-2-two-payments',
    AppRoutes.salary,
    signedIn: true,
    setup: _useTwoPayments,
  ),
  const _Scene(
    'sal-2-two-payments-all-inputs',
    AppRoutes.salary,
    signedIn: true,
    size: _tallPhone,
    setup: _useTwoPayments,
  ),
  _Scene(
    'sal-3-month-picker',
    AppRoutes.salary,
    signedIn: true,
    setup: (tester, demo) async {
      await tester.tap(find.byType(MonthChip));
      await tester.pumpAndSettle();
    },
  ),
  _Scene(
    'sal-4-switch-to-one',
    AppRoutes.salary,
    signedIn: true,
    setup: (tester, demo) async {
      await _useTwoPayments(tester, demo);
      await _tapPaymentSegment(tester, 0);
    },
  ),
  _Scene(
    'sal-5-switch-to-two',
    AppRoutes.salary,
    signedIn: true,
    setup: (tester, demo) => _tapPaymentSegment(tester, 1),
  ),
  _Scene(
    'sal-10-month-saved',
    AppRoutes.salary,
    signedIn: true,
    setup: (tester, demo) => _tapSaveMonth(tester),
  ),
  _Scene(
    'err-1-could-not-save',
    AppRoutes.salary,
    signedIn: true,
    setup: (tester, demo) async {
      demo.update(demo.settings.copyWith(save: DemoSave.fails));
      await _tapSaveMonth(tester);
    },
  ),
  _Scene(
    'sal-11-new-empty-month',
    AppRoutes.salary,
    signedIn: true,
    size: _tallPhone,
    setup: (tester, demo) => _useScenario(tester, demo, DemoScenario.empty),
  ),
  _Scene(
    'sal-11-new-empty-month-two-payments',
    AppRoutes.salary,
    signedIn: true,
    size: _tallPhone,
    setup: (tester, demo) async {
      demo.update(
        demo.settings.copyWith(
          scenario: DemoScenario.empty,
          paymentMode: PaymentMode.twoPayments,
        ),
      );
      await tester.pumpAndSettle();
    },
  ),
  _Scene(
    'sal-12-loading',
    AppRoutes.salary,
    signedIn: true,
    setup: (tester, demo) async {
      demo.update(const DemoSettings(scenario: DemoScenario.loading));
      await tester.pump(const Duration(milliseconds: 100));
    },
  ),
  _Scene(
    'sal-13-error',
    AppRoutes.salary,
    signedIn: true,
    setup: (tester, demo) => _useScenario(tester, demo, DemoScenario.error),
  ),
  _Scene(
    'sal-14-no-connection',
    AppRoutes.salary,
    signedIn: true,
    setup: (tester, demo) =>
        _useScenario(tester, demo, DemoScenario.noConnection),
  ),
  const _Scene(
    'sal-wide-two-payments',
    AppRoutes.salary,
    signedIn: true,
    size: Size(1280, 800),
    setup: _useTwoPayments,
  ),
  const _Scene('sal-6-history', AppRoutes.salaryHistory, signedIn: true),
  const _Scene(
    'sal-7-history-two-payments',
    AppRoutes.salaryHistory,
    signedIn: true,
    setup: _useTwoPayments,
  ),
  const _Scene('sal-8-compare-months', AppRoutes.salaryCompare, signedIn: true),
  _Scene(
    'sal-9-compare-parts',
    AppRoutes.salaryCompare,
    signedIn: true,
    setup: (tester, demo) async {
      await _useTwoPayments(tester, demo);
      await _tapPartSegment(tester, 2);
    },
  ),
  const _Scene(
    'sal-9-compare-whole-month-two-payments',
    AppRoutes.salaryCompare,
    signedIn: true,
    setup: _useTwoPayments,
  ),
  _Scene(
    'sal-8-compare-unsaved-month',
    AppRoutes.salaryCompare,
    signedIn: true,
    setup: (tester, demo) async {
      await tester.tap(find.byType(MonthChip).last);
      await tester.pumpAndSettle();
      // October is the chosen month (a filled button), so the outlined ones
      // are January to September: the seventh is July.
      await tester.tap(
        find
            .descendant(
              of: find.byType(GridView),
              matching: find.byType(OutlinedButton),
            )
            .at(6),
      );
      await tester.tap(find.byType(FilledButton).last);
      await tester.pumpAndSettle();
    },
  ),
  _Scene(
    'sal-8-compare-month-picker',
    AppRoutes.salaryCompare,
    signedIn: true,
    setup: (tester, demo) async {
      await tester.tap(find.byType(MonthChip).first);
      await tester.pumpAndSettle();
    },
  ),
  _Scene(
    'sal-8-compare-large-text',
    AppRoutes.salaryCompare,
    signedIn: true,
    setup: (tester, demo) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();
    },
  ),
  const _Scene(
    'sal-8-compare-wide',
    AppRoutes.salaryCompare,
    signedIn: true,
    size: Size(1280, 800),
  ),
  _Scene(
    'sal-8-compare-loading',
    AppRoutes.salaryCompare,
    signedIn: true,
    setup: (tester, demo) async {
      demo.update(const DemoSettings(scenario: DemoScenario.loading));
      await tester.pump(const Duration(milliseconds: 100));
    },
  ),
  _Scene(
    'sal-8-compare-no-connection',
    AppRoutes.salaryCompare,
    signedIn: true,
    setup: (tester, demo) =>
        _useScenario(tester, demo, DemoScenario.noConnection),
  ),
  _Scene(
    'sal-15-history-empty',
    AppRoutes.salaryHistory,
    signedIn: true,
    setup: (tester, demo) => _useScenario(tester, demo, DemoScenario.empty),
  ),
  _Scene(
    'sal-6-history-loading',
    AppRoutes.salaryHistory,
    signedIn: true,
    setup: (tester, demo) async {
      demo.update(const DemoSettings(scenario: DemoScenario.loading));
      await tester.pump(const Duration(milliseconds: 100));
    },
  ),
  _Scene(
    'sal-6-history-no-connection',
    AppRoutes.salaryHistory,
    signedIn: true,
    setup: (tester, demo) =>
        _useScenario(tester, demo, DemoScenario.noConnection),
  ),
  const _Scene(
    'sal-6-history-wide',
    AppRoutes.salaryHistory,
    signedIn: true,
    size: Size(1280, 800),
  ),
  const _Scene(
    'sal-1b-edit-month',
    '/salary/history/2026-09',
    signedIn: true,
    size: _tallPhone,
  ),
  const _Scene(
    'sal-1b-edit-month-two-payments',
    '/salary/history/2026-09',
    signedIn: true,
    size: _tallPhone,
    setup: _useTwoPayments,
  ),
  _Scene(
    'sal-1b-edit-month-changed',
    '/salary/history/2026-09',
    signedIn: true,
    size: _tallPhone,
    setup: (tester, demo) async {
      await tester.enterText(find.byType(TextField).at(4), '6');
      await tester.pumpAndSettle();
    },
  ),
  _Scene(
    'sal-1b-discard-changes',
    '/salary/history/2026-09',
    signedIn: true,
    setup: (tester, demo) async {
      await tester.enterText(find.byType(TextField).at(4), '6');
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
    },
  ),
  _Scene(
    'sal-1c-delete-month',
    '/salary/history/2026-09',
    signedIn: true,
    setup: (tester, demo) async {
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byWidgetPredicate((widget) => widget is PopupMenuItem).first,
      );
      await tester.pumpAndSettle();
    },
  ),
  const _Scene('fix-1-fixed-items', AppRoutes.fixedItems, signedIn: true),
  const _Scene(
    'fix-2-fixed-items-two-payments',
    AppRoutes.fixedItems,
    signedIn: true,
    setup: _useTwoPayments,
  ),
  _Scene(
    'fix-2-fixed-items-part-2',
    AppRoutes.fixedItems,
    signedIn: true,
    setup: (tester, demo) async {
      await _useTwoPayments(tester, demo);
      await _tapFixedPart(tester, 1);
    },
  ),
  _Scene(
    'fix-3-add-fixed-item',
    AppRoutes.fixedItems,
    signedIn: true,
    setup: (tester, demo) async {
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
    },
  ),
  _Scene(
    'fix-3-add-fixed-item-filled',
    AppRoutes.fixedItems,
    signedIn: true,
    setup: (tester, demo) async {
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      final fields = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(TextField),
      );
      await tester.enterText(fields.at(0), 'Gym');
      await tester.enterText(fields.at(1), '1200');
      await tester.pumpAndSettle();
    },
  ),
  _Scene(
    'fix-4-edit-fixed-item',
    AppRoutes.fixedItems,
    signedIn: true,
    setup: (tester, demo) async {
      await _useTwoPayments(tester, demo);
      await _openEditSheet(tester);
    },
  ),
  _Scene(
    'fix-5-delete-fixed-item',
    AppRoutes.fixedItems,
    signedIn: true,
    setup: (tester, demo) async {
      await _useTwoPayments(tester, demo);
      await _openEditSheet(tester);
      // The segments are not text buttons, so Delete is the first of them.
      await tester.tap(
        find
            .descendant(
              of: find.byType(BottomSheet),
              matching: find.byType(TextButton),
            )
            .first,
      );
      await tester.pumpAndSettle();
    },
  ),
  _Scene(
    'fix-8-copy-from-last-month-confirm',
    AppRoutes.fixedItems,
    signedIn: true,
    setup: (tester, demo) async {
      await tester.tap(find.byIcon(Icons.content_copy_outlined));
      await tester.pumpAndSettle();
    },
  ),
  _Scene(
    'fix-6-fixed-items-empty',
    AppRoutes.fixedItems,
    signedIn: true,
    setup: (tester, demo) async {
      // A saved month whose items are all deleted.
      for (var i = 0; i < 3; i++) {
        await _openEditSheet(tester);
        await tester.tap(
          find
              .descendant(
                of: find.byType(BottomSheet),
                matching: find.byType(TextButton),
              )
              .first,
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(
            of: find.byType(Dialog),
            matching: find.byType(FilledButton),
          ),
        );
        await tester.pumpAndSettle();
      }
    },
  ),
  _Scene(
    'fix-7-save-salary-first',
    AppRoutes.fixedItems,
    signedIn: true,
    setup: (tester, demo) => _useScenario(tester, demo, DemoScenario.empty),
  ),
  _Scene(
    'fix-7-save-salary-first-two-payments',
    AppRoutes.fixedItems,
    signedIn: true,
    setup: (tester, demo) async {
      demo.update(
        demo.settings.copyWith(
          scenario: DemoScenario.empty,
          paymentMode: PaymentMode.twoPayments,
        ),
      );
      await tester.pumpAndSettle();
    },
  ),
  _Scene(
    'fix-1-fixed-items-loading',
    AppRoutes.fixedItems,
    signedIn: true,
    setup: (tester, demo) async {
      demo.update(const DemoSettings(scenario: DemoScenario.loading));
      await tester.pump(const Duration(milliseconds: 100));
    },
  ),
  _Scene(
    'fix-1-fixed-items-no-connection',
    AppRoutes.fixedItems,
    signedIn: true,
    setup: (tester, demo) =>
        _useScenario(tester, demo, DemoScenario.noConnection),
  ),
  _Scene(
    'fix-2-fixed-items-large-text',
    AppRoutes.fixedItems,
    signedIn: true,
    setup: (tester, demo) async {
      await _useTwoPayments(tester, demo);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();
    },
  ),
  const _Scene(
    'fix-2-fixed-items-wide',
    AppRoutes.fixedItems,
    signedIn: true,
    size: Size(1280, 800),
    setup: _useTwoPayments,
  ),
  const _Scene('tx-1-transactions', AppRoutes.transactions, signedIn: true),
  const _Scene(
    'tx-2-transactions-two-payments',
    AppRoutes.transactions,
    signedIn: true,
    size: _tallPhone,
    setup: _useTwoPayments,
  ),
  _Scene(
    'tx-2b-transactions-part-2',
    AppRoutes.transactions,
    signedIn: true,
    setup: (tester, demo) async {
      await _useTwoPayments(tester, demo);
      await tester.tap(
        find
            .descendant(
              of: find.byType(PillSegmentedButton<PeriodScope>),
              matching: find.byType(Text),
            )
            .at(2),
      );
      await tester.pumpAndSettle();
    },
  ),
  _Scene(
    'tx-3-filters',
    AppRoutes.transactions,
    signedIn: true,
    setup: (tester, demo) async {
      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();
    },
  ),
  _Scene(
    'tx-3b-filters-two-payments',
    AppRoutes.transactions,
    signedIn: true,
    setup: (tester, demo) async {
      await _useTwoPayments(tester, demo);
      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();
    },
  ),
  _Scene(
    'tx-3c-filtered-by-category',
    AppRoutes.transactions,
    signedIn: true,
    setup: (tester, demo) async {
      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();
      // The first category chip of the sheet, then Apply.
      await tester.tap(find.byType(FilterChip).at(3));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FilledButton).last);
      await tester.pumpAndSettle();
    },
  ),
  const _Scene(
    'tx-4-add-transaction',
    AppRoutes.addTransaction,
    signedIn: true,
  ),
  _Scene(
    'tx-4b-add-transaction-filled',
    AppRoutes.addTransaction,
    signedIn: true,
    setup: (tester, demo) async {
      await tester.enterText(find.byType(TextField).first, '1284.50');
      await tester.tap(find.byType(ChoiceChip).first);
      await tester.pumpAndSettle();
    },
  ),
  _Scene(
    'err-1-could-not-save',
    AppRoutes.addTransaction,
    signedIn: true,
    setup: (tester, demo) async {
      await tester.enterText(find.byType(TextField).first, '1284.50');
      await tester.tap(find.byType(ChoiceChip).first);
      await tester.pumpAndSettle();
      demo.update(demo.settings.copyWith(scenario: DemoScenario.noConnection));
      await tester.tap(find.byType(FilledButton).last);
      // The snack bar goes away by itself after a few seconds, so no
      // settling: let it slide in and stop.
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
    },
  ),
  const _Scene(
    'tx-4c-add-transaction-two-payments',
    AppRoutes.addTransaction,
    signedIn: true,
    setup: _useTwoPayments,
  ),
  const _Scene(
    'tx-5-edit-transaction',
    '/transactions/edit/seed-groceries',
    signedIn: true,
  ),
  _Scene(
    'tx-6-choose-account',
    AppRoutes.addTransaction,
    signedIn: true,
    setup: (tester, demo) async {
      await tester.tap(find.byIcon(Icons.expand_more));
      await tester.pumpAndSettle();
    },
  ),
  _Scene(
    'tx-7-delete-transaction',
    '/transactions/edit/seed-groceries',
    signedIn: true,
    setup: (tester, demo) async {
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
    },
  ),
  _Scene(
    'tx-8-no-results',
    AppRoutes.transactions,
    signedIn: true,
    setup: (tester, demo) async {
      await tester.enterText(find.byType(TextField).first, 'xyz');
      await tester.pumpAndSettle();
    },
  ),
  _Scene(
    'tx-9-loading',
    AppRoutes.transactions,
    signedIn: true,
    setup: (tester, demo) async {
      demo.update(const DemoSettings(scenario: DemoScenario.loading));
      await tester.pump(const Duration(milliseconds: 100));
    },
  ),
  _Scene(
    'tx-10-empty',
    AppRoutes.transactions,
    signedIn: true,
    setup: (tester, demo) => _useScenario(tester, demo, DemoScenario.empty),
  ),
  _Scene(
    'tx-11-error',
    AppRoutes.transactions,
    signedIn: true,
    setup: (tester, demo) => _useScenario(tester, demo, DemoScenario.error),
  ),
  _Scene(
    'tx-12-no-connection',
    AppRoutes.transactions,
    signedIn: true,
    setup: (tester, demo) =>
        _useScenario(tester, demo, DemoScenario.noConnection),
  ),
  const _Scene(
    'tx-wide-two-payments',
    AppRoutes.transactions,
    signedIn: true,
    size: Size(1280, 800),
    setup: _useTwoPayments,
  ),
  const _Scene('db-1-debts', AppRoutes.debts, signedIn: true),
  _Scene(
    'db-1b-debts-borrowed',
    AppRoutes.debts,
    signedIn: true,
    setup: (tester, demo) async {
      await tester.tap(
        find
            .descendant(
              of: find.byType(PillSegmentedButton<DebtsFilter>),
              matching: find.byType(Text),
            )
            .at(2),
      );
      await tester.pumpAndSettle();
    },
  ),
  const _Scene('db-2-add-debt', AppRoutes.addDebt, signedIn: true),
  _Scene(
    'db-2b-add-debt-filled',
    AppRoutes.addDebt,
    signedIn: true,
    setup: (tester, demo) async {
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'Sam');
      await tester.enterText(fields.at(1), '10000');
      await tester.pumpAndSettle();
    },
  ),
  const _Scene('db-3-debt-details', '/debts/sam', signedIn: true),
  const _Scene('db-3b-debt-overdue', '/debts/maria', signedIn: true),
  const _Scene('db-3c-debt-settled', '/debts/anna', signedIn: true),
  const _Scene('db-4-add-repayment', '/debts/sam?repay=1', signedIn: true),
  _Scene(
    'db-5-edit-repayment',
    '/debts/sam',
    signedIn: true,
    setup: (tester, demo) async {
      await tester.tap(find.byIcon(Icons.chevron_right).first);
      await tester.pumpAndSettle();
    },
  ),
  _Scene(
    'db-6-delete-repayment',
    '/debts/sam',
    signedIn: true,
    setup: (tester, demo) async {
      await tester.tap(find.byIcon(Icons.chevron_right).first);
      await tester.pumpAndSettle();
      // The red button of the sheet is the first of its row: after the date.
      await tester.tap(
        find
            .descendant(
              of: find.byType(BottomSheet),
              matching: find.byType(TextButton),
            )
            .first,
      );
      await tester.pumpAndSettle();
    },
  ),
  _Scene(
    'db-7-delete-debt',
    '/debts/sam',
    signedIn: true,
    setup: (tester, demo) async {
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byWidgetPredicate((widget) => widget is PopupMenuItem).last,
      );
      await tester.pumpAndSettle();
    },
  ),
  const _Scene('db-8-edit-debt', '/debts/sam/edit', signedIn: true),
  _Scene(
    'db-9-loading',
    AppRoutes.debts,
    signedIn: true,
    setup: (tester, demo) async {
      demo.update(const DemoSettings(scenario: DemoScenario.loading));
      await tester.pump(const Duration(milliseconds: 100));
    },
  ),
  _Scene(
    'db-10-empty',
    AppRoutes.debts,
    signedIn: true,
    setup: (tester, demo) => _useScenario(tester, demo, DemoScenario.empty),
  ),
  _Scene(
    'db-11-error',
    AppRoutes.debts,
    signedIn: true,
    setup: (tester, demo) => _useScenario(tester, demo, DemoScenario.error),
  ),
  _Scene(
    'db-12-no-connection',
    AppRoutes.debts,
    signedIn: true,
    setup: (tester, demo) =>
        _useScenario(tester, demo, DemoScenario.noConnection),
  ),
  const _Scene(
    'db-wide',
    AppRoutes.debts,
    signedIn: true,
    size: Size(1280, 800),
  ),
  const _Scene('settings', AppRoutes.settings, signedIn: true),
  const _Scene('demo-panel', AppRoutes.demo),
  // F. Reports.
  const _Scene('rp-1-reports', AppRoutes.reports, signedIn: true),
  const _Scene(
    'rp-2-reports-two-payments',
    AppRoutes.reports,
    signedIn: true,
    size: _tallPhone,
    setup: _useTwoPayments,
  ),
  _Scene(
    'rp-2b-reports-part-1',
    AppRoutes.reports,
    signedIn: true,
    setup: (tester, demo) async {
      await _useTwoPayments(tester, demo);
      await _tapPartSegment(tester, 1);
    },
  ),
  _Scene(
    'rp-3-month-vs-month',
    AppRoutes.reports,
    signedIn: true,
    size: _tallPhone,
    setup: (tester, demo) => _tapReportsView(tester, 1),
  ),
  _Scene(
    'rp-4-part-vs-part',
    AppRoutes.reports,
    signedIn: true,
    size: _tallPhone,
    setup: (tester, demo) async {
      await _useTwoPayments(tester, demo);
      await _tapReportsView(tester, 1);
      await _tapPartSegment(tester, 1);
    },
  ),
  _Scene(
    'rp-3b-month-vs-month-two-payments',
    AppRoutes.reports,
    signedIn: true,
    size: _tallPhone,
    setup: (tester, demo) async {
      await _useTwoPayments(tester, demo);
      await _tapReportsView(tester, 1);
    },
  ),
  _Scene(
    'rp-5-debts',
    AppRoutes.reports,
    signedIn: true,
    setup: (tester, demo) => _tapReportsView(tester, 2),
  ),
  _Scene(
    'rp-6-loading',
    AppRoutes.reports,
    signedIn: true,
    setup: (tester, demo) async {
      demo.update(const DemoSettings(scenario: DemoScenario.loading));
      await tester.pump(const Duration(milliseconds: 100));
    },
  ),
  _Scene(
    'rp-7-empty',
    AppRoutes.reports,
    signedIn: true,
    setup: (tester, demo) => _useScenario(tester, demo, DemoScenario.empty),
  ),
  _Scene(
    'rp-8-error',
    AppRoutes.reports,
    signedIn: true,
    setup: (tester, demo) => _useScenario(tester, demo, DemoScenario.error),
  ),
  _Scene(
    'rp-9-no-connection',
    AppRoutes.reports,
    signedIn: true,
    setup: (tester, demo) =>
        _useScenario(tester, demo, DemoScenario.noConnection),
  ),

  // G. Settings, account and data.
  const _Scene(
    'st-1-settings',
    AppRoutes.settings,
    signedIn: true,
    size: Size(412, 1900),
  ),
  const _Scene('st-2-account', AppRoutes.account, signedIn: true),
  const _Scene(
    'st-3-pay-schedule',
    AppRoutes.paySchedule,
    signedIn: true,
    setup: _useTwoPayments,
  ),
  const _Scene('st-3b-pay-schedule-one', AppRoutes.paySchedule, signedIn: true),
  const _Scene('st-4-categories', AppRoutes.categories, signedIn: true),
  _Scene(
    'st-4b-edit-category',
    AppRoutes.categories,
    signedIn: true,
    setup: (tester, demo) async {
      await tester.tap(find.byIcon(Icons.edit_outlined).first);
      await tester.pumpAndSettle();
    },
  ),
  _Scene(
    'st-4c-add-category',
    AppRoutes.categories,
    signedIn: true,
    setup: (tester, demo) async {
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
    },
  ),
  const _Scene('st-5-accounts', AppRoutes.accounts, signedIn: true),
  _Scene(
    'st-5b-edit-account',
    AppRoutes.accounts,
    signedIn: true,
    setup: (tester, demo) async {
      await tester.tap(find.byIcon(Icons.edit_outlined).first);
      await tester.pumpAndSettle();
    },
  ),
  const _Scene(
    'st-6-change-password',
    AppRoutes.changePassword,
    signedIn: true,
  ),
  _Scene(
    'st-6b-change-password-filled',
    AppRoutes.changePassword,
    signedIn: true,
    setup: (tester, demo) async {
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'old-password');
      await tester.enterText(fields.at(1), 'new-password-1');
      await tester.enterText(fields.at(2), 'new-password-2');
      await tester.pumpAndSettle();
    },
  ),
  _Scene(
    'st-6c-change-password-refused',
    AppRoutes.changePassword,
    signedIn: true,
    setup: (tester, demo) async {
      demo.update(
        const DemoSettings(passwordChange: DemoPasswordChange.passwordRefused),
      );
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'old-password');
      await tester.enterText(fields.at(1), 'short');
      await tester.enterText(fields.at(2), 'short');
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
    },
  ),
  _Scene(
    'st-6d-change-password-locked',
    AppRoutes.changePassword,
    signedIn: true,
    setup: (tester, demo) async {
      demo.update(
        const DemoSettings(passwordChange: DemoPasswordChange.locked),
      );
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'old-password');
      await tester.enterText(fields.at(1), 'new-password-1');
      await tester.enterText(fields.at(2), 'new-password-1');
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
    },
  ),
  const _Scene('st-12-change-email', AppRoutes.changeEmail, signedIn: true),
  _Scene(
    'st-12b-change-email-taken',
    AppRoutes.changeEmail,
    signedIn: true,
    setup: (tester, demo) async {
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'taken@example.com');
      await tester.enterText(fields.at(1), 'secret-password');
      await tester.pumpAndSettle();
      await _tapPrimary(tester);
    },
  ),
  _Scene(
    'st-12c-change-email-code',
    AppRoutes.account,
    signedIn: true,
    setup: (tester, demo) async {
      await tester.tap(find.byIcon(Icons.alternate_email));
      await tester.pumpAndSettle();
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'dana.whitfield@example.com');
      await tester.enterText(fields.at(1), 'secret-password');
      await tester.pumpAndSettle();
      await _tapPrimary(tester);
    },
  ),
  _Scene(
    'st-7-export-csv',
    AppRoutes.settings,
    signedIn: true,
    size: _tallPhone,
    setup: (tester, demo) async {
      await tester.tap(find.byIcon(Icons.file_upload_outlined));
      await tester.pumpAndSettle();
    },
  ),
  _Scene(
    'st-7b-export-csv-custom',
    AppRoutes.settings,
    signedIn: true,
    size: _tallPhone,
    setup: (tester, demo) async {
      await tester.tap(find.byIcon(Icons.file_upload_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ChoiceChip).last);
      await tester.pumpAndSettle();
    },
  ),
  const _Scene('st-8-import-csv', AppRoutes.importCsv, signedIn: true),
  _Scene(
    'st-8b-import-result',
    AppRoutes.importCsv,
    signedIn: true,
    setup: (tester, demo) async {
      await tester.tap(find.byType(FilledButton).last);
      await tester.pumpAndSettle();
    },
  ),
  _Scene(
    'st-9-default-currency',
    AppRoutes.settings,
    signedIn: true,
    size: _tallPhone,
    setup: (tester, demo) async {
      await tester.tap(find.byIcon(Icons.currency_exchange));
      await tester.pumpAndSettle();
    },
  ),
  _Scene(
    'st-2b-edit-name',
    AppRoutes.account,
    signedIn: true,
    setup: (tester, demo) async {
      await tester.tap(find.byIcon(Icons.badge_outlined));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Dana Whitfield');
      await tester.pumpAndSettle();
    },
  ),
  _Scene(
    'st-2c-edit-name-failed',
    AppRoutes.account,
    signedIn: true,
    setup: (tester, demo) async {
      await tester.tap(find.byIcon(Icons.badge_outlined));
      await tester.pumpAndSettle();
      demo.update(const DemoSettings(scenario: DemoScenario.noConnection));
      await tester.enterText(find.byType(TextField), 'Dana Whitfield');
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FilledButton).last);
      await tester.pumpAndSettle();
    },
  ),
  _Scene(
    'st-10-sign-out',
    AppRoutes.account,
    signedIn: true,
    setup: (tester, demo) async {
      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();
    },
  ),
  _Scene(
    'st-11-delete-account',
    AppRoutes.account,
    signedIn: true,
    setup: (tester, demo) async {
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
    },
  ),
  _Scene(
    'st-11c-delete-account-locked',
    AppRoutes.account,
    signedIn: true,
    setup: (tester, demo) async {
      demo.update(
        const DemoSettings(passwordChange: DemoPasswordChange.locked),
      );
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'secret');
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FilledButton).last);
      await tester.pumpAndSettle();
    },
  ),
  _Scene(
    'st-11d-delete-account-busy',
    AppRoutes.account,
    signedIn: true,
    setup: (tester, demo) async {
      demo.update(
        const DemoSettings(passwordChange: DemoPasswordChange.unavailable),
      );
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'secret');
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FilledButton).last);
      await tester.pumpAndSettle();
    },
  ),
  _Scene(
    'st-11b-delete-account-wrong-password',
    AppRoutes.account,
    signedIn: true,
    setup: (tester, demo) async {
      demo.update(const DemoSettings(signIn: DemoSignIn.wrongPassword));
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'secret');
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FilledButton).last);
      await tester.pumpAndSettle();
    },
  ),
  _Scene(
    'st-4d-categories-error',
    AppRoutes.categories,
    signedIn: true,
    setup: (tester, demo) => _useScenario(tester, demo, DemoScenario.error),
  ),
  _Scene(
    'st-1b-settings-no-connection',
    AppRoutes.settings,
    signedIn: true,
    setup: (tester, demo) =>
        _useScenario(tester, demo, DemoScenario.noConnection),
  ),

  // J. Tablet and web layouts.
  const _Scene(
    'tb-1-transactions-wide',
    AppRoutes.transactions,
    signedIn: true,
    size: _wideWindow,
  ),
  const _Scene(
    'tb-2-overview-wide',
    AppRoutes.overview,
    signedIn: true,
    size: _wideWindow,
  ),
  const _Scene('tb-3-sign-in-web', AppRoutes.signIn, size: _wideWindow),
  _Scene(
    'tb-3b-sign-in-web-no-connection',
    AppRoutes.signIn,
    size: _wideWindow,
    setup: (tester, demo) async {
      demo.update(const DemoSettings(scenario: DemoScenario.noConnection));
      await _tapPrimary(tester);
    },
  ),
];

/// The screens that adapt to a wide window, drawn again at 1280 x 800 as
/// `web-<name>`.
const _webNames = {
  'auth-3-register',
  'auth-4-verify-email',
  'auth-6-pay-setup',
  'auth-7-forgot-password',
  'auth-11-app-lock',
  'ov-1-overview',
  'sal-1-salary',
  'sal-1b-edit-month-changed',
  'sal-6-history',
  'sal-8-compare-months',
  'fix-1-fixed-items',
  'tx-1-transactions',
  'tx-4b-add-transaction-filled',
  'tx-5-edit-transaction',
  'db-1-debts',
  'db-2-add-debt',
  'db-3-debt-details',
  'db-8-edit-debt',
  'rp-1-reports',
  'rp-3-month-vs-month',
  'rp-5-debts',
  'st-1-settings',
  'st-2-account',
  'st-3b-pay-schedule-one',
  'st-4-categories',
  'st-5-accounts',
  'st-8-import-csv',
};

final List<_Scene> _webScenes = [
  for (final scene in _scenes)
    if (_webNames.contains(scene.name))
      _Scene(
        'web-${scene.name}',
        scene.route,
        signedIn: scene.signedIn,
        setup: scene.setup,
        size: _wideWindow,
      ),
];

void main() {
  setUpAll(loadAppFonts);

  for (final scene in [..._scenes, ..._webScenes]) {
    for (final language in [AppLanguage.english, AppLanguage.arabic]) {
      for (final brightness in Brightness.values) {
        final name = '${scene.name}-${language.name}-${brightness.name}';

        testWidgets('draws $name', (tester) async {
          tester.view
            ..devicePixelRatio = 1
            ..physicalSize = scene.size;
          addTearDown(tester.view.reset);
          tester.platformDispatcher.platformBrightnessTestValue = brightness;
          addTearDown(
            tester.platformDispatcher.clearPlatformBrightnessTestValue,
          );

          final demo = DemoController(latency: Duration.zero);
          final auth = FakeAuthRepository(
            demo: demo,
            signedIn: scene.signedIn || scene.fingerprintKey,
          );
          final deviceKeys = FakeDeviceKeyRepository(demo: demo, auth: auth);
          if (scene.fingerprintKey) {
            await deviceKeys.enable(password: 'p', prompt: 'Confirm');
            await auth.signOut();
          }
          final key = GlobalKey();
          await tester.pumpWidget(
            RenderTarget(
              boundaryKey: key,
              child: buildApp(
                languageRepository: FakeLanguageRepository(language),
                // Available and not yet allowed, so the Settings show the
                // notification rows.
                pushMessaging: FakePushMessagingRepository(),
                demo: demo,
                authRepository: auth,
                deviceKeyRepository: deviceKeys,
                appLockRepository: InstantAppLockRepository(
                  deviceHasFingerprint: scene.sensor,
                  biometricsMatch: false,
                  pause: scene.pinPause,
                  pin: scene.lockOn ? '1234' : null,
                ),
                // The demo panel handle belongs to staging builds only and
                // would sit on top of every picture.
                environment: scene.route == AppRoutes.demo || scene.serverWaking
                    ? AppEnvironment.staging
                    : AppEnvironment.production,
                // The note about the sleeping server belongs to staging.
                serverActivity: scene.serverWaking
                    ? FakeServerActivity(isSlow: true)
                    : null,
              ),
            ),
          );
          await tester.pumpAndSettle();
          GoRouter.of(tester.element(find.byType(Scaffold).first))
              .go(scene.route);
          await tester.pumpAndSettle();
          await scene.setup?.call(tester, demo);

          // Pictures (the app icon) decode outside the test clock: give them
          // a moment, or they are missing from the image.
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
          await saveScreenshot(tester, key, name);
          // Let any pending fake answer (the slow "loading" one takes eight
          // seconds, and a screen may ask twice in a row) finish before the
          // test ends.
          await tester.pump(const Duration(seconds: 10));
          await tester.pump(const Duration(seconds: 10));
          await tester.pumpAndSettle();
        });
      }
    }
  }
}
