import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/environment/app_environment.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';
import 'package:money_scribe/core/payments/period_scope.dart';
import 'package:money_scribe/core/routing/app_routes.dart';
import 'package:money_scribe/core/widgets/month_chip.dart';
import 'package:money_scribe/features/auth/data/fake/fake_auth_repository.dart';
import 'package:money_scribe/features/salary/domain/fixed_item.dart';
import 'package:money_scribe/features/settings/domain/app_language.dart';

import '../support/build_app.dart';
import '../support/fake_language_repository.dart';
import '../support/render_screen.dart';

/// The render check: every screen and state is drawn to a picture in English
/// and Arabic, light and dark, into `build/screens/`, to be looked at. The test
/// also fails if a screen throws.

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
  });

  final String name;
  final String route;
  final bool signedIn;
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
        of: find.byType(SegmentedButton<PaymentMode>),
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
          of: find.byType(SegmentedButton<PeriodScope>),
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
          of: find.byType(SegmentedButton<FixedItemPart>).first,
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

const _tallPhone = Size(412, 1800);

final _scenes = <_Scene>[
  const _Scene('auth-1-welcome', AppRoutes.welcome),
  const _Scene('auth-2-sign-in', AppRoutes.signIn),
  _Scene(
    'auth-2b-sign-in-wrong',
    AppRoutes.signIn,
    setup: (tester, demo) async {
      demo.update(const DemoSettings(signIn: DemoSignIn.wrongPassword));
      await _tapPrimary(tester);
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
      await tester.enterText(fields.at(1), 'alex@example.com');
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await _tapPrimary(tester);
    },
  ),
  _Scene(
    'auth-4-verify-email',
    AppRoutes.verifyEmail,
    setup: (tester, demo) => _typeCode(tester, '48'),
  ),
  _Scene(
    'auth-4b-verify-wrong',
    AppRoutes.verifyEmail,
    setup: (tester, demo) async {
      demo.update(const DemoSettings(code: DemoCode.wrong));
      await _typeCode(tester, '4817');
    },
  ),
  _Scene(
    'auth-4c-verify-expired',
    AppRoutes.verifyEmail,
    setup: (tester, demo) async {
      demo.update(const DemoSettings(code: DemoCode.expired));
      await _typeCode(tester, '4817');
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
    'auth-8-reset-code',
    AppRoutes.resetCode,
    setup: (tester, demo) => _typeCode(tester, '6'),
  ),
  _Scene(
    'auth-8b-reset-wrong',
    AppRoutes.resetCode,
    setup: (tester, demo) async {
      demo.update(const DemoSettings(code: DemoCode.wrong));
      await _typeCode(tester, '6205');
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
  const _Scene('auth-10-password-changed', AppRoutes.passwordChanged),
  const _Scene('auth-11-app-lock', AppRoutes.appLock),
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
              of: find.byType(SegmentedButton<PeriodScope>),
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
      // After the four segments (Income, Expense, Part 1, Part 2) comes Delete.
      await tester.tap(
        find
            .descendant(
              of: find.byType(BottomSheet),
              matching: find.byType(TextButton),
            )
            .at(4),
      );
      await tester.pumpAndSettle();
    },
  ),
  _Scene(
    'fix-6-fixed-items-empty',
    AppRoutes.fixedItems,
    signedIn: true,
    setup: (tester, demo) => _useScenario(tester, demo, DemoScenario.empty),
  ),
  _Scene(
    'fix-6-fixed-items-empty-part',
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
  const _Scene('settings', AppRoutes.settings, signedIn: true),
  const _Scene('demo-panel', AppRoutes.demo),
];

void main() {
  setUpAll(loadAppFonts);

  for (final scene in _scenes) {
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
          final key = GlobalKey();
          await tester.pumpWidget(
            RenderTarget(
              boundaryKey: key,
              child: buildApp(
                languageRepository: FakeLanguageRepository(language),
                demo: demo,
                authRepository: FakeAuthRepository(
                  demo: demo,
                  signedIn: scene.signedIn,
                ),
                // The demo panel handle belongs to staging builds only and
                // would sit on top of every picture.
                environment: scene.route == AppRoutes.demo
                    ? AppEnvironment.staging
                    : AppEnvironment.production,
              ),
            ),
          );
          await tester.pumpAndSettle();
          GoRouter.of(tester.element(find.byType(Scaffold).first))
              .go(scene.route);
          await tester.pumpAndSettle();
          await scene.setup?.call(tester, demo);

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
