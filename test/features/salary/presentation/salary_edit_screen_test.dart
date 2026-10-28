import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';
import 'package:money_scribe/core/widgets/month_chip.dart';
import 'package:money_scribe/features/salary/presentation/salary_edit_screen.dart';
import 'package:money_scribe/features/salary/presentation/salary_history_screen.dart';
import 'package:money_scribe/features/settings/domain/app_language.dart';

import 'salary_test_helpers.dart';

late DemoController _demo;

/// Opens September 2026 from the history.
Future<void> _openSeptember(
  WidgetTester tester, {
  DemoSettings settings = const DemoSettings(),
  AppLanguage language = AppLanguage.english,
  Size size = tallPhone,
}) async {
  _demo = await pumpHistory(
    tester,
    settings: settings,
    language: language,
    size: size,
  );
  final row = settings.paymentMode == PaymentMode.twoPayments
      ? find.textContaining('20 Sep')
      : find.text(
          language == AppLanguage.arabic ? 'سبتمبر 2026' : 'September 2026',
        );
  await tester.tap(row);
  await tester.pumpAndSettle();
}

Finder _field(String label) => find.widgetWithText(TextField, label);

Finder get _saveChanges => find.widgetWithText(FilledButton, 'Save changes');

bool _isEnabled(WidgetTester tester, Finder button) {
  return tester.widget<FilledButton>(button).onPressed != null;
}

Future<void> _openMenu(WidgetTester tester) async {
  await tester.tap(find.byIcon(LucideIcons.ellipsisVertical));
  await tester.pumpAndSettle();
}

Future<void> _chooseDelete(WidgetTester tester) async {
  await _openMenu(tester);
  await tester.tap(find.text('Delete month'));
  await tester.pumpAndSettle();
}

void main() {
  group('a saved month (SAL-1b)', () {
    testWidgets('shows the saved numbers under the month', (tester) async {
      await _openSeptember(tester);

      expect(find.byType(SalaryEditScreen), findsOneWidget);
      expect(find.widgetWithText(AppBar, 'Salary'), findsOneWidget);
      expect(find.text('September 2026'), findsOneWidget);
      expect(amountText('100,050.00 ₽'), findsOneWidget);
      expect(find.text('4 extra hours'), findsOneWidget);
      expect(_field('Extra hours'), findsOneWidget);
      expect(
        tester.widget<TextField>(_field('Extra hours')).controller!.text,
        '4',
      );
    });

    testWidgets('has no bottom bar, no segments and a month that is fixed', (
      tester,
    ) async {
      await _openSeptember(tester);

      expect(find.byType(NavigationBar), findsNothing);
      expect(find.byType(BackButton), findsOneWidget);
      expect(find.text('Fixed items'), findsNothing);
      expect(find.byType(MonthChip), findsOneWidget);
      expect(find.byIcon(LucideIcons.chevronDown), findsNothing);
      expect(find.byTooltip('Salary history'), findsNothing);
    });

    testWidgets('Save changes waits for a change', (tester) async {
      await _openSeptember(tester);

      expect(find.text('Save month'), findsNothing);
      expect(_isEnabled(tester, _saveChanges), isFalse);

      await tester.enterText(_field('Extra hours'), '8');
      await tester.pumpAndSettle();
      expect(amountText('104,400.00 ₽'), findsOneWidget);
      expect(_isEnabled(tester, _saveChanges), isTrue);

      await tester.enterText(_field('Extra hours'), '4');
      await tester.pumpAndSettle();
      expect(_isEnabled(tester, _saveChanges), isFalse);
    });

    testWidgets('an invalid change cannot be saved', (tester) async {
      await _openSeptember(tester);

      await tester.enterText(_field('Working days in the month'), '40');
      await tester.pumpAndSettle();

      expect(_isEnabled(tester, _saveChanges), isFalse);
    });

    testWidgets('saving goes back to the history, which shows the change', (
      tester,
    ) async {
      await _openSeptember(tester);

      await tester.enterText(_field('Extra hours'), '8');
      await tester.pumpAndSettle();
      await tester.tap(_saveChanges);
      await tester.pumpAndSettle();

      expect(find.byType(SalaryHistoryScreen), findsOneWidget);
      expect(find.byType(SalaryEditScreen), findsNothing);
      expect(find.text('Month saved'), findsOneWidget);
      expect(amountText('100,050.00 ₽'), findsNothing);
      expect(amountText('104,400.00 ₽'), findsNWidgets(3));
    });

    testWidgets('a failed save stays on the month and offers Retry', (
      tester,
    ) async {
      await _openSeptember(tester);
      _demo.update(_demo.settings.copyWith(save: DemoSave.fails));

      await tester.enterText(_field('Extra hours'), '8');
      await tester.pumpAndSettle();
      await tester.tap(_saveChanges);
      await tester.pumpAndSettle();

      expect(find.byType(SalaryEditScreen), findsOneWidget);
      expect(find.text("Couldn't save. Check your connection."), findsOne);

      _demo.update(_demo.settings.copyWith(save: DemoSave.accepted));
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.byType(SalaryHistoryScreen), findsOneWidget);
      expect(find.text('Month saved'), findsOneWidget);
    });

    testWidgets('splitting the month asks first and is saved with it', (
      tester,
    ) async {
      await _openSeptember(tester);

      await tester.tap(find.text('Two payments'));
      await tester.pumpAndSettle();
      expect(find.text('Switch to two payments?'), findsOneWidget);

      await tester.tap(find.text('Switch'));
      await tester.pumpAndSettle();
      expect(find.text('Part 1 · paid 20 Sep'), findsOneWidget);
      expect(_isEnabled(tester, _saveChanges), isTrue);

      await tester.tap(_saveChanges);
      await tester.pumpAndSettle();

      // The month keeps its own schedule: it is paid twice from now on.
      expect(find.text('Part 1 · paid 20 Sep'), findsOneWidget);
      expect(find.text('Part 2 · paid 5 Oct'), findsOneWidget);
    });

    testWidgets('a month paid in two payments shows both parts', (
      tester,
    ) async {
      await _openSeptember(
        tester,
        settings: const DemoSettings(paymentMode: PaymentMode.twoPayments),
      );

      expect(find.text('Part 1 · paid 20 Sep'), findsOneWidget);
      expect(find.text('Part 2 · paid 5 Oct'), findsOneWidget);
      expect(amountText('56,550.00 ₽'), findsOneWidget);
    });
  });

  group('leaving with unsaved changes', () {
    testWidgets('going back without a change leaves at once', (tester) async {
      await _openSeptember(tester);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.byType(SalaryHistoryScreen), findsOneWidget);
      expect(find.text('Discard changes?'), findsNothing);
    });

    testWidgets('asks before dropping a change', (tester) async {
      await _openSeptember(tester);
      await tester.enterText(_field('Extra hours'), '8');
      await tester.pumpAndSettle();

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('Discard changes?'), findsOneWidget);
      expect(
        find.text('Your changes to September 2026 have not been saved.'),
        findsOneWidget,
      );
    });

    testWidgets('Keep editing stays on the month with the change', (
      tester,
    ) async {
      await _openSeptember(tester);
      await tester.enterText(_field('Extra hours'), '8');
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();

      expect(find.byType(SalaryEditScreen), findsOneWidget);
      expect(amountText('104,400.00 ₽'), findsOneWidget);
    });

    testWidgets('Discard goes back to the history with nothing changed', (
      tester,
    ) async {
      await _openSeptember(tester);
      await tester.enterText(_field('Extra hours'), '8');
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      expect(find.byType(SalaryHistoryScreen), findsOneWidget);
      expect(find.text('Month saved'), findsNothing);
      expect(amountText('100,050.00 ₽'), findsOneWidget);
    });

    testWidgets('the system back gesture asks too', (tester) async {
      await _openSeptember(tester);
      await tester.enterText(_field('Extra hours'), '8');
      await tester.pumpAndSettle();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('Discard changes?'), findsOneWidget);
    });
  });

  group('deleting (SAL-1c)', () {
    testWidgets('the menu has one item, Delete month', (tester) async {
      await _openSeptember(tester);

      await _openMenu(tester);

      expect(find.text('Delete month'), findsOneWidget);
    });

    testWidgets('asks to confirm, naming the month', (tester) async {
      await _openSeptember(tester);

      await _chooseDelete(tester);

      expect(find.text('Delete September 2026?'), findsOneWidget);
      expect(
        find.text(
          'This month and its fixed items will be permanently deleted from '
          'your account. This cannot be undone.',
        ),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Delete'), findsOneWidget);
    });

    testWidgets('Cancel keeps the month', (tester) async {
      await _openSeptember(tester);
      await _chooseDelete(tester);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(SalaryEditScreen), findsOneWidget);
      expect(find.text('Delete September 2026?'), findsNothing);
    });

    testWidgets('Delete removes the month and goes back to the history', (
      tester,
    ) async {
      await _openSeptember(tester);
      await _chooseDelete(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(find.byType(SalaryHistoryScreen), findsOneWidget);
      expect(find.text('Month deleted'), findsOneWidget);
      expect(find.text('September 2026'), findsNothing);
      expect(find.text('October 2026'), findsOneWidget);
      expect(find.text('August 2026'), findsOneWidget);
    });

    testWidgets('deleting the only month leaves an empty history', (
      tester,
    ) async {
      await pumpHistory(tester);
      for (final month in ['October 2026', 'August 2026', 'September 2026']) {
        await tester.tap(find.text(month));
        await tester.pumpAndSettle();
        await _chooseDelete(tester);
        await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
        await tester.pumpAndSettle();
      }

      expect(find.text('No saved months yet'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('a failed deletion stays on the month and offers Retry', (
      tester,
    ) async {
      await _openSeptember(tester);
      _demo.update(_demo.settings.copyWith(save: DemoSave.fails));
      await _chooseDelete(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(find.byType(SalaryEditScreen), findsOneWidget);
      expect(find.text("Couldn't delete. Check your connection."), findsOne);

      _demo.update(_demo.settings.copyWith(save: DemoSave.accepted));
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.byType(SalaryHistoryScreen), findsOneWidget);
      expect(find.text('Month deleted'), findsOneWidget);
    });
  });

  group('states', () {
    testWidgets('a month that is not saved has no menu to delete it', (
      tester,
    ) async {
      await pumpApp(tester);

      unawaited(
        GoRouter.of(tester.element(find.byType(Scaffold).first))
            .push<Object?>('/salary/history/2025-01'),
      );
      await tester.pumpAndSettle();

      expect(find.text('January 2025'), findsOneWidget);
      expect(find.byIcon(LucideIcons.ellipsisVertical), findsNothing);
      expect(find.text('Fill in the inputs to see the results.'), findsOne);
    });

    testWidgets('an error offers Try again', (tester) async {
      await _openSeptember(tester);

      _demo.update(_demo.settings.copyWith(scenario: DemoScenario.error));
      await tester.pumpAndSettle();

      expect(find.text("Couldn't load this month"), findsOneWidget);
      expect(find.byIcon(LucideIcons.ellipsisVertical), findsNothing);

      _demo.update(const DemoSettings());
      await tester.pumpAndSettle();
      expect(amountText('100,050.00 ₽'), findsOneWidget);
    });
  });

  group('in Arabic', () {
    testWidgets('shows Arabic labels and mirrors the app bar', (tester) async {
      await _openSeptember(tester, language: AppLanguage.arabic);

      expect(find.text('حفظ التغييرات'), findsOneWidget);
      final width = tester.view.physicalSize.width;
      expect(
        tester.getCenter(find.byType(BackButton)).dx,
        greaterThan(width / 2),
        reason: 'the back arrow is on the right',
      );
      expect(
        tester.getCenter(find.byIcon(LucideIcons.ellipsisVertical)).dx,
        lessThan(width / 2),
        reason: 'the menu is on the left',
      );

      await tester.tap(find.byIcon(LucideIcons.ellipsisVertical));
      await tester.pumpAndSettle();
      expect(find.text('حذف الشهر'), findsOneWidget);
    });
  });
}
