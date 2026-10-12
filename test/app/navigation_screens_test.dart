import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/widgets/amount_row.dart';
import 'package:money_scribe/core/widgets/pill_segmented_button.dart';
import 'package:money_scribe/core/widgets/wide_frame.dart';
import 'package:money_scribe/features/auth/data/fake/fake_auth_repository.dart';
import 'package:money_scribe/features/auth/presentation/account_screen.dart';
import 'package:money_scribe/features/auth/presentation/change_password_screen.dart';
import 'package:money_scribe/features/auth/presentation/welcome_screen.dart';
import 'package:money_scribe/features/debts/presentation/debt_details_screen.dart';
import 'package:money_scribe/features/debts/presentation/debt_form_screen.dart';
import 'package:money_scribe/features/debts/presentation/debts_screen.dart';
import 'package:money_scribe/features/overview/presentation/overview_screen.dart';
import 'package:money_scribe/features/reports/bloc/reports_bloc.dart';
import 'package:money_scribe/features/reports/presentation/reports_screen.dart';
import 'package:money_scribe/features/reports/presentation/widgets/donut_chart.dart';
import 'package:money_scribe/features/salary/presentation/fixed_items_screen.dart';
import 'package:money_scribe/features/salary/presentation/salary_compare_screen.dart';
import 'package:money_scribe/features/salary/presentation/salary_history_screen.dart';
import 'package:money_scribe/features/salary/presentation/salary_screen.dart';
import 'package:money_scribe/features/settings/presentation/csv_import_screen.dart';
import 'package:money_scribe/features/settings/presentation/pay_schedule_screen.dart';
import 'package:money_scribe/features/settings/presentation/settings_screen.dart';
import 'package:money_scribe/features/transactions/presentation/accounts_screen.dart';
import 'package:money_scribe/features/transactions/presentation/categories_screen.dart';
import 'package:money_scribe/features/transactions/presentation/transaction_form_screen.dart';
import 'package:money_scribe/features/transactions/presentation/transactions_screen.dart';

import '../support/build_app.dart';
import '../support/fake_push_messaging_repository.dart';

/// The link test of the signed-in app: every button of the main screens leads
/// where the design says (the "goes to" tables of the screen prompts). The
/// authentication flow is in `navigation_test.dart`.

const _phone = Size(412, 915);
const _wide = Size(1280, 800);

/// Opens the app signed in, on the Overview.
Future<void> _open(WidgetTester tester, {Size size = _phone}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size;
  addTearDown(tester.view.reset);
  final demo = DemoController(latency: Duration.zero);
  await tester.pumpWidget(
    buildApp(
      demo: demo,
      pushMessaging: FakePushMessagingRepository(),
      authRepository: FakeAuthRepository(demo: demo, signedIn: true),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _navigation() {
  return find.byWidgetPredicate(
    (widget) => widget is NavigationBar || widget is NavigationRail,
  );
}

/// Goes to a tab by its label in the navigation bar or rail.
Future<void> _tab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: _navigation(), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
  await tester.tap(finder.first);
  await tester.pumpAndSettle();
}

Future<void> _tapText(WidgetTester tester, String text) {
  return _tap(tester, find.text(text));
}

/// Goes back with the back arrow of the app bar.
Future<void> _back(WidgetTester tester) async {
  await tester.tap(find.byType(BackButton));
  await tester.pumpAndSettle();
}

/// Taps the segment [label] of the choice with the value type [T].
Future<void> _segment<T>(WidgetTester tester, String label) async {
  await _tap(
    tester,
    find.descendant(
      of: find.byType(PillSegmentedButton<T>).first,
      matching: find.text(label),
    ),
  );
}

void _expectBar(WidgetTester tester, {required bool shown}) {
  expect(find.byType(NavigationBar), shown ? findsOneWidget : findsNothing);
}

void main() {
  group('the navigation bar and rail', () {
    testWidgets('lead to the five top-level screens', (tester) async {
      await _open(tester);
      expect(find.byType(OverviewScreen), findsOneWidget);

      await _tab(tester, 'Salary');
      expect(find.byType(SalaryScreen), findsOneWidget);
      await _tab(tester, 'Transactions');
      expect(find.byType(TransactionsScreen), findsOneWidget);
      await _tab(tester, 'Debts');
      expect(find.byType(DebtsScreen), findsOneWidget);
      await _tab(tester, 'Reports');
      expect(find.byType(ReportsScreen), findsOneWidget);
      await _tab(tester, 'Overview');
      expect(find.byType(OverviewScreen), findsOneWidget);
    });

    testWidgets('are a rail on a wide window, with the same links', (
      tester,
    ) async {
      await _open(tester, size: _wide);

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      await _tab(tester, 'Transactions');
      expect(find.byType(TransactionsScreen), findsOneWidget);
      await _tab(tester, 'Debts');
      expect(find.byType(DebtsScreen), findsOneWidget);
    });

    testWidgets('the Settings gear is on every top-level screen', (
      tester,
    ) async {
      await _open(tester);

      for (final tab in [
        'Overview',
        'Salary',
        'Transactions',
        'Debts',
        'Reports',
      ]) {
        await _tab(tester, tab);
        await _tap(tester, find.byTooltip('Settings'));
        expect(find.byType(SettingsScreen), findsOneWidget, reason: tab);
        _expectBar(tester, shown: false);
        await _back(tester);
      }
    });
  });

  group('Overview', () {
    testWidgets('the salary row opens the Salary tab', (tester) async {
      await _open(tester);

      await _tap(tester, find.widgetWithText(AmountRow, 'Salary'));

      expect(find.byType(SalaryScreen), findsOneWidget);
      _expectBar(tester, shown: true);
    });

    testWidgets('the recurring income and fixed costs rows open the fixed '
        'items', (tester) async {
      await _open(tester);

      await _tap(tester, find.widgetWithText(AmountRow, 'Recurring income'));
      expect(find.byType(FixedItemsScreen), findsOneWidget);
      _expectBar(tester, shown: true);

      await _tab(tester, 'Overview');
      await _tap(tester, find.widgetWithText(AmountRow, 'Fixed costs'));
      expect(find.byType(FixedItemsScreen), findsOneWidget);
    });

    testWidgets('the purchases row opens the Transactions', (tester) async {
      await _open(tester);

      await _tap(tester, find.widgetWithText(AmountRow, 'Purchases'));

      expect(find.byType(TransactionsScreen), findsOneWidget);
    });

    testWidgets('the debt movements row opens the Debts', (tester) async {
      await _open(tester);

      await _tap(tester, find.widgetWithText(AmountRow, 'Debt movements'));

      expect(find.byType(DebtsScreen), findsOneWidget);
    });

    testWidgets('Add purchase opens the form without the bar, and back '
        'returns', (tester) async {
      await _open(tester);

      await _tapText(tester, 'Add purchase');

      expect(find.byType(TransactionFormScreen), findsOneWidget);
      expect(find.text('Add transaction'), findsOneWidget);
      _expectBar(tester, shown: false);

      await _back(tester);
      expect(find.byType(OverviewScreen), findsOneWidget);
    });

    testWidgets('Add repayment asks which debt, then opens it', (tester) async {
      await _open(tester);

      await _tapText(tester, 'Add repayment');
      expect(find.text('Choose a debt'), findsOneWidget);

      await _tap(
        tester,
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('Sam'),
        ),
      );

      expect(find.byType(DebtDetailsScreen), findsOneWidget);
      _expectBar(tester, shown: false);
    });
  });

  group('Salary', () {
    testWidgets('the History icon opens the saved months, and Compare opens '
        'the comparison', (tester) async {
      await _open(tester);
      await _tab(tester, 'Salary');

      await _tap(tester, find.byTooltip('Salary history'));
      expect(find.byType(SalaryHistoryScreen), findsOneWidget);

      await _tap(tester, find.byTooltip('Compare months'));
      expect(find.byType(SalaryCompareScreen), findsOneWidget);

      await _back(tester);
      await _back(tester);
      expect(find.byType(SalaryScreen), findsOneWidget);
    });

    testWidgets('Fixed items is the second segment and keeps the bar', (
      tester,
    ) async {
      await _open(tester);
      await _tab(tester, 'Salary');

      await _tapText(tester, 'Fixed items');

      expect(find.byType(FixedItemsScreen), findsOneWidget);
      _expectBar(tester, shown: true);
    });
  });

  group('Transactions', () {
    testWidgets('Add opens the form for a new one', (tester) async {
      await _open(tester);
      await _tab(tester, 'Transactions');

      await _tapText(tester, 'Add');

      expect(find.text('Add transaction'), findsOneWidget);
      _expectBar(tester, shown: false);
    });

    testWidgets('a row opens the transaction to be changed', (tester) async {
      await _open(tester);
      await _tab(tester, 'Transactions');

      await _tapText(tester, 'Groceries');

      expect(find.text('Edit transaction'), findsOneWidget);
    });

    testWidgets('Filters opens the sheet', (tester) async {
      await _open(tester);
      await _tab(tester, 'Transactions');

      await _tap(tester, find.byIcon(Icons.tune));

      expect(find.byType(BottomSheet), findsOneWidget);
    });
  });

  group('Debts', () {
    testWidgets('Add debt opens the form', (tester) async {
      await _open(tester);
      await _tab(tester, 'Debts');

      await _tapText(tester, 'Add debt');

      expect(find.byType(DebtFormScreen), findsOneWidget);
      expect(find.text('Add debt'), findsOneWidget);
    });

    testWidgets('a debt opens its details, and Edit opens the form', (
      tester,
    ) async {
      await _open(tester);
      await _tab(tester, 'Debts');

      await _tapText(tester, 'Sam');
      expect(find.byType(DebtDetailsScreen), findsOneWidget);

      await _tap(tester, find.byIcon(Icons.more_vert));
      await _tapText(tester, 'Edit');
      expect(find.text('Edit debt'), findsOneWidget);
    });

    testWidgets('Add repayment opens the sheet on the details', (tester) async {
      await _open(tester);
      await _tab(tester, 'Debts');
      await _tapText(tester, 'Sam');

      await _tapText(tester, 'Add repayment');

      expect(find.byType(BottomSheet), findsOneWidget);
    });
  });

  group('Reports', () {
    testWidgets('a category opens the Transactions narrowed to it', (
      tester,
    ) async {
      await _open(tester);
      await _tab(tester, 'Reports');

      await _tap(tester, find.text('Groceries'));

      expect(find.byType(TransactionsScreen), findsOneWidget);
      _expectBar(tester, shown: true);
    });

    testWidgets('a debt of the Debts view opens its details', (tester) async {
      await _open(tester);
      await _tab(tester, 'Reports');
      await _segment<ReportsView>(tester, 'Debts');

      await _tapText(tester, 'Sam');

      expect(find.byType(DebtDetailsScreen), findsOneWidget);
    });
  });

  group('Settings', () {
    Future<void> openSettings(WidgetTester tester) async {
      await _open(tester);
      await _tap(tester, find.byTooltip('Settings'));
    }

    testWidgets('the account row opens the Account', (tester) async {
      await openSettings(tester);

      await _tapText(tester, 'Alex');

      expect(find.byType(AccountScreen), findsOneWidget);
    });

    testWidgets('Pay schedule opens its screen', (tester) async {
      await openSettings(tester);

      await _tapText(tester, 'Pay schedule');

      expect(find.byType(PayScheduleScreen), findsOneWidget);
    });

    testWidgets('Default currency opens a sheet', (tester) async {
      await openSettings(tester);

      await _tapText(tester, 'Default currency');

      expect(find.byType(BottomSheet), findsOneWidget);
    });

    testWidgets('Categories and Accounts open their screens', (tester) async {
      await openSettings(tester);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
      await tester.pumpAndSettle();

      await _tapText(tester, 'Categories');
      expect(find.byType(CategoriesScreen), findsOneWidget);
      await _back(tester);

      await _tapText(tester, 'Accounts');
      expect(find.byType(AccountsScreen), findsOneWidget);
    });

    testWidgets('Export CSV opens a sheet and Import CSV its screen', (
      tester,
    ) async {
      await openSettings(tester);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
      await tester.pumpAndSettle();

      await _tapText(tester, 'Export CSV');
      expect(find.byType(BottomSheet), findsOneWidget);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      await _tapText(tester, 'Import CSV');
      expect(find.byType(CsvImportScreen), findsOneWidget);
    });

    testWidgets('Change password opens its screen from the Account', (
      tester,
    ) async {
      await openSettings(tester);
      await _tapText(tester, 'Alex');

      await _tapText(tester, 'Change password');

      expect(find.byType(ChangePasswordScreen), findsOneWidget);
    });

    testWidgets('Sign out asks first, and confirming leads to the Welcome', (
      tester,
    ) async {
      await openSettings(tester);
      await _tapText(tester, 'Alex');

      await _tapText(tester, 'Sign out');
      expect(find.byType(AlertDialog), findsOneWidget);

      await _tap(tester, find.widgetWithText(FilledButton, 'Sign out'));

      expect(find.byType(WelcomeScreen), findsOneWidget);
    });
  });

  group('a wide window', () {
    testWidgets('Settings lists its sections beside the chosen one', (
      tester,
    ) async {
      await _open(tester, size: _wide);
      await _tap(tester, find.byTooltip('Settings'));

      // The account is the first section.
      expect(find.text('Alex'), findsOneWidget);
      expect(find.text('Theme'), findsNothing);

      await _tapText(tester, 'Preferences');
      expect(find.text('Theme'), findsOneWidget);
      expect(find.text('Alex'), findsNothing);

      await _tapText(tester, 'Data');
      await _tapText(tester, 'Categories');
      expect(find.byType(CategoriesScreen), findsOneWidget);
    });

    testWidgets('a pushed screen is one centred column', (tester) async {
      await _open(tester, size: _wide);

      await _tapText(tester, 'Add purchase');

      final form = tester.getRect(find.byType(TransactionFormScreen));
      expect(form.width, FrameWidth.regular.value);
      expect(form.center.dx, 640);
    });

    testWidgets('a narrow form is a narrower column', (tester) async {
      await _open(tester, size: _wide);
      await _tap(tester, find.byTooltip('Settings'));
      await _tapText(tester, 'Payments');

      await _tapText(tester, 'Pay schedule');

      expect(
        tester.getRect(find.byType(PayScheduleScreen)).width,
        FrameWidth.narrow.value,
      );
    });

    testWidgets('the Reports categories sit beside the chart', (tester) async {
      await _open(tester, size: _wide);
      await _tab(tester, 'Reports');

      expect(
        tester.getTopLeft(find.byType(DonutChart)).dx,
        lessThan(tester.getTopLeft(find.text('Housing')).dx),
      );
    });

    testWidgets('the sign-in screen has the brand panel', (tester) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = _wide;
      addTearDown(tester.view.reset);
      final demo = DemoController(latency: Duration.zero);
      await tester.pumpWidget(
        buildApp(
          demo: demo,
          authRepository: FakeAuthRepository(demo: demo),
        ),
      );
      await tester.pumpAndSettle();

      await _tapText(tester, 'Sign in');

      // The name is in the panel and in the question at the bottom.
      expect(
        find.text('Your salary, purchases and debts in one place.'),
        findsOneWidget,
      );
    });
  });
}
