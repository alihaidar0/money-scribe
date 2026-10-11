import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/features/debts/presentation/debts_screen.dart';
import 'package:money_scribe/features/overview/presentation/overview_screen.dart';
import 'package:money_scribe/features/reports/presentation/reports_screen.dart';
import 'package:money_scribe/features/salary/presentation/salary_screen.dart';
import 'package:money_scribe/features/settings/domain/app_language.dart';
import 'package:money_scribe/features/transactions/presentation/transactions_screen.dart';

import '../../support/build_app.dart';
import '../../support/fake_language_repository.dart';

Future<void> _pumpApp(
  WidgetTester tester, {
  Size size = const Size(412, 915),
  AppLanguage language = AppLanguage.english,
}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    buildApp(
      signedIn: true,
      languageRepository: FakeLanguageRepository(language),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('on a phone', () {
    testWidgets('shows the navigation bar with five labelled destinations', (
      tester,
    ) async {
      await _pumpApp(tester);

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
      for (final label in [
        'Overview',
        'Salary',
        'Transactions',
        'Debts',
        'Reports',
      ]) {
        expect(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text(label),
          ),
          findsOneWidget,
          reason: label,
        );
      }
    });

    testWidgets('opens every top-level screen from the bar', (tester) async {
      await _pumpApp(tester);
      final screens = {
        'Salary': SalaryScreen,
        'Transactions': TransactionsScreen,
        'Debts': DebtsScreen,
        'Reports': ReportsScreen,
        'Overview': OverviewScreen,
      };

      for (final MapEntry(key: label, value: type) in screens.entries) {
        await tester.tap(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text(label),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(type), findsOneWidget, reason: label);
        expect(find.widgetWithText(AppBar, label), findsOneWidget);
      }
    });

    testWidgets('every top-level screen has the Settings gear', (tester) async {
      await _pumpApp(tester);

      expect(find.byTooltip('Settings'), findsOneWidget);

      await tester.tap(find.text('Debts'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Settings'), findsOneWidget);
    });
  });

  group('on a tablet or the web', () {
    testWidgets('swaps the bar for a rail from 840 dp', (tester) async {
      await _pumpApp(tester, size: const Size(840, 800));

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('keeps the bar just below 840 dp', (tester) async {
      await _pumpApp(tester, size: const Size(839, 800));

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
    });

    testWidgets('the rail switches screens too, with labels shown', (
      tester,
    ) async {
      await _pumpApp(tester, size: const Size(1280, 800));

      await tester.tap(
        find.descendant(
          of: find.byType(NavigationRail),
          matching: find.text('Transactions'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TransactionsScreen), findsOneWidget);
    });
  });

  testWidgets('the bar and the rail mirror in Arabic', (tester) async {
    await _pumpApp(tester, language: AppLanguage.arabic);
    final overview = tester.getCenter(find.text('نظرة عامة').last).dx;
    final reports = tester.getCenter(find.text('التقارير')).dx;

    expect(overview, greaterThan(reports));
  });
}
