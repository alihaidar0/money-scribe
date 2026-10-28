import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:money_scribe/app/shell/floating_navigation_bar.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';
import 'package:money_scribe/core/widgets/month_chip.dart';
import 'package:money_scribe/core/widgets/skeleton.dart';
import 'package:money_scribe/features/salary/presentation/salary_compare_screen.dart';
import 'package:money_scribe/features/salary/presentation/salary_edit_screen.dart';
import 'package:money_scribe/features/salary/presentation/salary_history_screen.dart';
import 'package:money_scribe/features/salary/presentation/salary_screen.dart';
import 'package:money_scribe/features/settings/domain/app_language.dart';

import 'salary_test_helpers.dart';

void main() {
  group('one payment (SAL-6)', () {
    testWidgets('has a card for each saved month, the newest first', (
      tester,
    ) async {
      await pumpHistory(tester);

      expect(find.byType(SalaryHistoryScreen), findsOneWidget);
      expect(find.text('Salary history'), findsOneWidget);
      for (final month in ['October 2026', 'September 2026', 'August 2026']) {
        expect(find.text(month), findsOneWidget);
      }
      expect(amountText('104,400.00 ₽'), findsNWidgets(2));
      expect(amountText('100,050.00 ₽'), findsOneWidget);
      expect(find.text('Total after tax'), findsNWidgets(3));

      final october = tester.getTopLeft(find.text('October 2026')).dy;
      final september = tester.getTopLeft(find.text('September 2026')).dy;
      final august = tester.getTopLeft(find.text('August 2026')).dy;
      expect(october, lessThan(september));
      expect(september, lessThan(august));
    });

    testWidgets('has the back arrow, the Compare icon and New month', (
      tester,
    ) async {
      await pumpHistory(tester);

      expect(find.byType(BackButton), findsOneWidget);
      expect(find.byTooltip('Compare months'), findsOneWidget);
      expect(find.widgetWithText(FloatingActionButton, 'New month'), findsOne);
      expect(find.byType(FloatingNavigationBar), findsNothing);
    });

    testWidgets('the back arrow goes back to the Salary screen', (
      tester,
    ) async {
      await pumpHistory(tester);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.byType(SalaryScreen), findsOneWidget);
      expect(find.byType(FloatingNavigationBar), findsOneWidget);
    });
  });

  group('two payments (SAL-7)', () {
    testWidgets('has a header and a row for each part of every month', (
      tester,
    ) async {
      await pumpHistory(
        tester,
        settings: const DemoSettings(paymentMode: PaymentMode.twoPayments),
      );

      for (final month in ['October 2026', 'September 2026', 'August 2026']) {
        expect(find.text(month), findsOneWidget);
      }
      expect(find.text('Part 1 · paid 20 Oct'), findsOneWidget);
      expect(find.text('Part 2 · paid 5 Nov'), findsOneWidget);
      expect(find.text('Part 1 · paid 20 Sep'), findsOneWidget);
      expect(find.text('Part 2 · paid 5 Oct'), findsOneWidget);
      expect(find.text('Part 1 · paid 20 Aug'), findsOneWidget);
      expect(find.text('Part 2 · paid 5 Sep'), findsOneWidget);
      expect(amountText('43,500.00 ₽'), findsNWidgets(3));
      expect(amountText('60,900.00 ₽'), findsNWidgets(2));
      expect(amountText('56,550.00 ₽'), findsOneWidget);
      expect(find.text('Total after tax'), findsNothing);
    });

    testWidgets('either part opens the month', (tester) async {
      await pumpHistory(
        tester,
        settings: const DemoSettings(paymentMode: PaymentMode.twoPayments),
      );

      await tester.tap(find.text('Part 2 · paid 5 Oct'));
      await tester.pumpAndSettle();

      expect(find.byType(SalaryEditScreen), findsOneWidget);
      expect(find.text('September 2026'), findsOneWidget);
    });
  });

  group('opening a month', () {
    testWidgets('a card opens that month to be corrected', (tester) async {
      await pumpHistory(tester);

      await tester.tap(find.text('September 2026'));
      await tester.pumpAndSettle();

      expect(find.byType(SalaryEditScreen), findsOneWidget);
      expect(amountText('100,050.00 ₽'), findsOneWidget);
    });

    testWidgets('the Compare icon opens the comparison', (tester) async {
      await pumpHistory(tester);

      await tester.tap(find.byTooltip('Compare months'));
      await tester.pumpAndSettle();

      expect(find.byType(SalaryCompareScreen), findsOneWidget);
    });
  });

  group('a new month', () {
    testWidgets('opens the latest month without a saved salary, empty', (
      tester,
    ) async {
      await pumpHistory(tester);

      await tester.tap(find.text('New month'));
      await tester.pumpAndSettle();

      expect(find.byType(SalaryScreen), findsOneWidget);
      expect(find.byType(SalaryHistoryScreen), findsNothing);
      expect(find.byType(FloatingNavigationBar), findsOneWidget);
      // August to October are saved, so the month is July.
      expect(find.text('July 2026'), findsOneWidget);
      expect(find.text('Fill in the inputs to see the results.'), findsOne);
    });

    testWidgets('opens it again after another month was chosen', (
      tester,
    ) async {
      await pumpHistory(tester);
      await tester.tap(find.text('New month'));
      await tester.pumpAndSettle();

      // Choose another month, then ask for a new month once more.
      await tester.tap(find.byType(MonthChip));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mar'));
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.text('March 2026'), findsOneWidget);

      await tester.tap(find.byTooltip('Salary history'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('New month'));
      await tester.pumpAndSettle();

      expect(find.text('July 2026'), findsOneWidget);
    });
  });

  group('an empty history (SAL-15)', () {
    testWidgets('says no month was saved and offers Enter a month', (
      tester,
    ) async {
      await pumpHistory(
        tester,
        settings: const DemoSettings(scenario: DemoScenario.empty),
      );

      expect(find.text('No saved months yet'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Enter a month'), findsOne);
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.byTooltip('Compare months'), findsOneWidget);
    });

    testWidgets('Enter a month opens an empty month of today', (tester) async {
      await pumpHistory(
        tester,
        settings: const DemoSettings(scenario: DemoScenario.empty),
      );

      await tester.tap(find.text('Enter a month'));
      await tester.pumpAndSettle();

      expect(find.byType(SalaryScreen), findsOneWidget);
      expect(find.text('October 2026'), findsOneWidget);
      expect(find.text('Fill in the inputs to see the results.'), findsOne);
    });
  });

  group('loading, error and no connection', () {
    testWidgets('shows grey blocks while the months load', (tester) async {
      final demo = await pumpHistory(tester, size: const Size(412, 915));

      demo.update(demo.settings.copyWith(scenario: DemoScenario.loading));
      // Long enough for the button to finish leaving.
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(SkeletonBox), findsWidgets);
      expect(find.byType(FloatingActionButton), findsNothing);

      demo.update(const DemoSettings());
      await tester.pump(const Duration(seconds: 9));
      await tester.pumpAndSettle();
      expect(find.byType(SkeletonBox), findsNothing);
    });

    testWidgets('an error offers Try again, which loads the months', (
      tester,
    ) async {
      final demo = await pumpHistory(tester);

      demo.update(demo.settings.copyWith(scenario: DemoScenario.error));
      await tester.pumpAndSettle();
      expect(find.text('Something went wrong'), findsOneWidget);

      demo.update(const DemoSettings());
      await tester.pumpAndSettle();

      expect(find.text('October 2026'), findsOneWidget);
    });

    testWidgets('no connection offers Try again', (tester) async {
      final demo = await pumpHistory(
        tester,
        settings: const DemoSettings(scenario: DemoScenario.noConnection),
      );

      expect(find.text('No connection'), findsOneWidget);

      demo.update(const DemoSettings());
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();
      expect(find.text('October 2026'), findsOneWidget);
    });
  });

  group('addresses', () {
    testWidgets('a month that does not exist shows the history', (
      tester,
    ) async {
      await pumpApp(tester);

      GoRouter.of(tester.element(find.byType(Scaffold).first))
          .go('/salary/history/not-a-month');
      await tester.pumpAndSettle();

      expect(find.byType(SalaryHistoryScreen), findsOneWidget);
    });

    testWidgets('the Salary tab opens the month in its address', (
      tester,
    ) async {
      await pumpApp(tester);

      GoRouter.of(tester.element(find.byType(Scaffold).first))
          .go('/salary?month=2026-09');
      await tester.pumpAndSettle();

      expect(find.text('September 2026'), findsOneWidget);
      expect(amountText('100,050.00 ₽'), findsOneWidget);
    });
  });

  group('in Arabic', () {
    testWidgets('shows Arabic labels, Western digits and mirrored rows', (
      tester,
    ) async {
      await pumpHistory(
        tester,
        language: AppLanguage.arabic,
        settings: const DemoSettings(paymentMode: PaymentMode.twoPayments),
      );

      expect(find.text('سجل الرواتب'), findsOneWidget);
      expect(find.textContaining('الجزء 1 · يُدفع في 20'), findsNWidgets(3));
      expect(find.textContaining(RegExp('[٠-٩]')), findsNothing);
      expect(find.text('شهر جديد'), findsOneWidget);
    });

    testWidgets('an empty history says so in Arabic', (tester) async {
      await pumpHistory(
        tester,
        language: AppLanguage.arabic,
        settings: const DemoSettings(scenario: DemoScenario.empty),
      );

      expect(find.text('لا توجد أشهر محفوظة بعد'), findsOneWidget);
      expect(find.text('أدخل شهرًا'), findsOneWidget);
    });
  });
}
