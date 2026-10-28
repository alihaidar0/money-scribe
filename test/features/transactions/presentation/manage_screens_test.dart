import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:money_scribe/app/shell/floating_navigation_bar.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/widgets/pill_segmented_button.dart';
import 'package:money_scribe/core/widgets/skeleton.dart';
import 'package:money_scribe/features/settings/domain/app_language.dart';
import 'package:money_scribe/features/transactions/domain/account.dart';
import 'package:money_scribe/features/transactions/presentation/accounts_screen.dart';
import 'package:money_scribe/features/transactions/presentation/categories_screen.dart';

import '../../../support/open_screen.dart';

Finder inSheet(Finder finder) =>
    find.descendant(of: find.byType(BottomSheet), matching: finder);

Future<DemoController> openRows(
  WidgetTester tester,
  String english, {
  DemoSettings settings = const DemoSettings(),
  AppLanguage language = AppLanguage.english,
  String? arabic,
}) async {
  final demo = await openSettings(
    tester,
    settings: settings,
    language: language,
  );
  await tester.tap(
    find.text(language == AppLanguage.arabic ? arabic! : english),
  );
  await tester.pumpAndSettle();
  return demo;
}

void main() {
  group('the categories (ST-4)', () {
    testWidgets('lists the built-in ones as Default and the custom one', (
      tester,
    ) async {
      await openRows(tester, 'Categories');

      expect(find.byType(CategoriesScreen), findsOneWidget);
      expect(find.widgetWithText(AppBar, 'Categories'), findsOneWidget);
      expect(find.byType(FloatingNavigationBar), findsNothing);
      for (final name in [
        'Groceries',
        'Dining',
        'Transport',
        'Housing',
        'Utilities',
        'Scholarship',
        'Other',
        'Gifts',
      ]) {
        expect(find.text(name), findsOneWidget, reason: name);
      }
      expect(find.text('Default'), findsNWidgets(7));
      expect(find.byTooltip('Edit Gifts'), findsOneWidget);
      expect(find.text('Add category'), findsOneWidget);
    });

    testWidgets('a built-in row does nothing', (tester) async {
      await openRows(tester, 'Categories');

      await tester.tap(find.text('Groceries'));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('the custom row opens the edit sheet, filled in', (
      tester,
    ) async {
      await openRows(tester, 'Categories');

      await tester.tap(find.text('Gifts'));
      await tester.pumpAndSettle();

      expect(inSheet(find.text('Edit category')), findsOneWidget);
      expect(
        tester
            .widget<TextField>(inSheet(find.byType(TextField)))
            .controller
            ?.text,
        'Gifts',
      );
      expect(inSheet(find.text('Delete')), findsOneWidget);
      expect(inSheet(find.text('Cancel')), findsOneWidget);
      expect(inSheet(find.text('Save')), findsOneWidget);
      // Eight pictures to choose from, the first of them chosen.
      expect(inSheet(find.byIcon(LucideIcons.circleCheck)), findsOneWidget);
      expect(inSheet(find.byType(InkWell)), findsWidgets);
    });

    testWidgets('Save changes the name', (tester) async {
      await openRows(tester, 'Categories');
      await tester.tap(find.text('Gifts'));
      await tester.pumpAndSettle();

      await tester.enterText(inSheet(find.byType(TextField)), 'Presents');
      await tester.pumpAndSettle();
      await tester.tap(inSheet(find.text('Save')));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('Presents'), findsOneWidget);
      expect(find.text('Gifts'), findsNothing);
    });

    testWidgets('Add category adds one at the end', (tester) async {
      await openRows(tester, 'Categories');

      await tester.tap(find.text('Add category'));
      await tester.pumpAndSettle();
      expect(inSheet(find.text('Add category')), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              inSheet(find.widgetWithText(FilledButton, 'Save')),
            )
            .onPressed,
        isNull,
      );

      await tester.enterText(inSheet(find.byType(TextField)), 'Pets');
      await tester.pumpAndSettle();
      await tester.tap(inSheet(find.text('Save')));
      await tester.pumpAndSettle();

      expect(find.text('Pets'), findsOneWidget);
      expect(find.byTooltip('Edit Pets'), findsOneWidget);
    });

    testWidgets('Cancel closes the sheet and changes nothing', (tester) async {
      await openRows(tester, 'Categories');
      await tester.tap(find.text('Gifts'));
      await tester.pumpAndSettle();
      await tester.enterText(inSheet(find.byType(TextField)), 'Presents');

      await tester.tap(inSheet(find.text('Cancel')));
      await tester.pumpAndSettle();

      expect(find.text('Gifts'), findsOneWidget);
    });

    testWidgets('Delete asks first, then removes the category', (tester) async {
      await openRows(tester, 'Categories');
      await tester.tap(find.text('Gifts'));
      await tester.pumpAndSettle();

      await tester.tap(inSheet(find.text('Delete')));
      await tester.pumpAndSettle();

      expect(find.text('Delete category?'), findsOneWidget);
      expect(
        find.text('Gifts will be removed. Its transactions move to Other.'),
        findsOneWidget,
      );

      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Delete'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Gifts'), findsNothing);
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('Cancel in the dialog keeps the category', (tester) async {
      await openRows(tester, 'Categories');
      await tester.tap(find.text('Gifts'));
      await tester.pumpAndSettle();
      await tester.tap(inSheet(find.text('Delete')));
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Cancel'),
        ),
      );
      await tester.pumpAndSettle();

      expect(inSheet(find.text('Edit category')), findsOneWidget);
    });

    testWidgets('a failed save offers Retry', (tester) async {
      final demo = await openRows(tester, 'Categories');
      await tester.tap(find.text('Add category'));
      await tester.pumpAndSettle();
      await tester.enterText(inSheet(find.byType(TextField)), 'Pets');
      await tester.pumpAndSettle();
      demo.update(const DemoSettings(save: DemoSave.fails));

      await tester.tap(inSheet(find.text('Save')));
      await tester.pumpAndSettle();

      expect(
        find.text("Couldn't save. Check your connection."),
        findsOneWidget,
      );
      expect(find.text('Pets'), findsNothing);

      demo.update(const DemoSettings());
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Pets'), findsOneWidget);
    });

    testWidgets('shows a skeleton, then the error with Try again', (
      tester,
    ) async {
      final demo = await openRows(
        tester,
        'Categories',
        settings: const DemoSettings(scenario: DemoScenario.error),
      );

      expect(find.text("Couldn't load categories"), findsOneWidget);
      expect(find.text('Add category'), findsNothing);

      demo.update(const DemoSettings());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.text('Groceries'), findsOneWidget);
    });

    testWidgets('is in Arabic, with Western digits and mirrored', (
      tester,
    ) async {
      await openRows(
        tester,
        'Categories',
        language: AppLanguage.arabic,
        arabic: 'الفئات',
      );

      expect(find.widgetWithText(AppBar, 'الفئات'), findsOneWidget);
      expect(find.text('إضافة فئة'), findsOneWidget);
      expect(find.text('افتراضية'), findsNWidgets(7));
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows the built-in categories by their key, in Arabic', (
      tester,
    ) async {
      await openRows(
        tester,
        'Categories',
        language: AppLanguage.arabic,
        arabic: 'الفئات',
      );

      for (final name in [
        'البقالة',
        'المطاعم',
        'المواصلات',
        'السكن',
        'الخدمات',
        'المنحة الدراسية',
        'أخرى',
      ]) {
        expect(find.text(name), findsOneWidget, reason: name);
      }
      // The English names the fake server sends are not shown.
      expect(find.text('Groceries'), findsNothing);
      // The category the person made keeps the name they typed.
      expect(find.text('Gifts'), findsOneWidget);
    });

    testWidgets('a name another category has cannot be saved', (tester) async {
      await openRows(tester, 'Categories');
      await tester.tap(find.text('Add category'));
      await tester.pumpAndSettle();

      for (final name in ['gifts', 'GROCERIES', ' Other ']) {
        await tester.enterText(inSheet(find.byType(TextField)), name);
        await tester.pumpAndSettle();

        expect(
          inSheet(find.text('A category with this name already exists.')),
          findsOneWidget,
          reason: name,
        );
        expect(
          tester
              .widget<FilledButton>(
                inSheet(find.widgetWithText(FilledButton, 'Save')),
              )
              .onPressed,
          isNull,
          reason: name,
        );
      }
    });

    testWidgets('the own name stays allowed while editing', (tester) async {
      await openRows(tester, 'Categories');
      await tester.tap(find.text('Gifts'));
      await tester.pumpAndSettle();

      expect(
        inSheet(find.text('A category with this name already exists.')),
        findsNothing,
      );
      expect(
        tester
            .widget<FilledButton>(
              inSheet(find.widgetWithText(FilledButton, 'Save')),
            )
            .onPressed,
        isNotNull,
      );
    });

    testWidgets('an Arabic name of a built-in category cannot be taken', (
      tester,
    ) async {
      await openRows(
        tester,
        'Categories',
        language: AppLanguage.arabic,
        arabic: 'الفئات',
      );
      await tester.tap(find.text('إضافة فئة'));
      await tester.pumpAndSettle();

      await tester.enterText(inSheet(find.byType(TextField)), 'البقالة');
      await tester.pumpAndSettle();

      expect(inSheet(find.text('توجد فئة بهذا الاسم بالفعل.')), findsOneWidget);
    });
  });

  group('the accounts (ST-5)', () {
    testWidgets('lists the card and cash, each with an edit icon', (
      tester,
    ) async {
      await openRows(tester, 'Accounts');

      expect(find.byType(AccountsScreen), findsOneWidget);
      expect(find.widgetWithText(AppBar, 'Accounts'), findsOneWidget);
      expect(find.text('Card'), findsOneWidget);
      expect(find.text('Cash'), findsOneWidget);
      expect(find.byIcon(LucideIcons.creditCard), findsOneWidget);
      expect(find.byIcon(LucideIcons.pencil), findsNWidgets(2));
      expect(find.text('Add account'), findsOneWidget);
    });

    testWidgets('a row opens the edit sheet with the kind chosen', (
      tester,
    ) async {
      await openRows(tester, 'Accounts');

      await tester.tap(find.text('Cash'));
      await tester.pumpAndSettle();

      expect(inSheet(find.text('Edit account')), findsOneWidget);
      expect(inSheet(find.text('Card')), findsOneWidget);
      expect(inSheet(find.text('Other')), findsOneWidget);
      final kinds = tester.widget<PillSegmentedButton<AccountKind>>(
        inSheet(find.byType(PillSegmentedButton<AccountKind>)),
      );
      expect(kinds.selected, {AccountKind.cash});
    });

    testWidgets('Add account adds one', (tester) async {
      await openRows(tester, 'Accounts');

      await tester.tap(find.text('Add account'));
      await tester.pumpAndSettle();
      await tester.enterText(inSheet(find.byType(TextField)), 'Savings');
      await tester.pumpAndSettle();
      await tester.tap(inSheet(find.text('Other')));
      await tester.pumpAndSettle();
      await tester.tap(inSheet(find.text('Save')));
      await tester.pumpAndSettle();

      expect(find.text('Savings'), findsOneWidget);
      expect(find.byIcon(LucideIcons.wallet), findsWidgets);
    });

    testWidgets('an account with transactions cannot be deleted', (
      tester,
    ) async {
      await openRows(tester, 'Accounts');
      await tester.tap(find.text('Card'));
      await tester.pumpAndSettle();
      await tester.tap(inSheet(find.text('Delete')));
      await tester.pumpAndSettle();
      expect(find.text('Delete account?'), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Delete'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text("This account has transactions, so it can't be deleted."),
        findsOneWidget,
      );
      expect(find.text('Card'), findsOneWidget);
    });

    testWidgets('an account one added can be deleted', (tester) async {
      await openRows(tester, 'Accounts');
      await tester.tap(find.text('Add account'));
      await tester.pumpAndSettle();
      await tester.enterText(inSheet(find.byType(TextField)), 'Savings');
      await tester.pumpAndSettle();
      await tester.tap(inSheet(find.text('Save')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Savings'));
      await tester.pumpAndSettle();
      await tester.tap(inSheet(find.text('Delete')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Delete'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Savings'), findsNothing);
    });

    testWidgets('shows a skeleton while loading', (tester) async {
      final demo = await openRows(tester, 'Accounts');
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      demo.update(const DemoSettings(scenario: DemoScenario.loading));
      await tester.pump();

      await tester.tap(find.text('Accounts'));
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(SkeletonBox), findsWidgets);

      await tester.pump(const Duration(seconds: 20));
      await tester.pumpAndSettle();
    });

    testWidgets('offers Try again with no connection', (tester) async {
      final demo = await openRows(
        tester,
        'Accounts',
        settings: const DemoSettings(scenario: DemoScenario.noConnection),
      );

      expect(find.text('No connection'), findsOneWidget);

      demo.update(const DemoSettings());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.text('Card'), findsOneWidget);
    });

    testWidgets('is in Arabic', (tester) async {
      await openRows(
        tester,
        'Accounts',
        language: AppLanguage.arabic,
        arabic: 'الحسابات',
      );

      expect(find.widgetWithText(AppBar, 'الحسابات'), findsOneWidget);
      expect(find.text('إضافة حساب'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a name another account has cannot be saved', (tester) async {
      await openRows(tester, 'Accounts');
      await tester.tap(find.text('Add account'));
      await tester.pumpAndSettle();

      await tester.enterText(inSheet(find.byType(TextField)), ' cash ');
      await tester.pumpAndSettle();

      expect(
        inSheet(find.text('You already have an account with this name.')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<FilledButton>(
              inSheet(find.widgetWithText(FilledButton, 'Save')),
            )
            .onPressed,
        isNull,
      );
    });

    testWidgets('keeping the own name while editing is fine', (tester) async {
      await openRows(tester, 'Accounts');
      await tester.tap(find.text('Cash'));
      await tester.pumpAndSettle();

      expect(
        inSheet(find.text('You already have an account with this name.')),
        findsNothing,
      );
    });
  });
}
