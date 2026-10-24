import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';
import 'package:money_scribe/features/auth/presentation/account_screen.dart';
import 'package:money_scribe/features/auth/presentation/create_pin_screen.dart';
import 'package:money_scribe/features/settings/domain/app_language.dart';
import 'package:money_scribe/features/settings/domain/theme_choice.dart';
import 'package:money_scribe/features/settings/presentation/csv_import_screen.dart';
import 'package:money_scribe/features/settings/presentation/pay_schedule_screen.dart';
import 'package:money_scribe/features/settings/presentation/settings_screen.dart';
import 'package:money_scribe/features/transactions/presentation/accounts_screen.dart';
import 'package:money_scribe/features/transactions/presentation/categories_screen.dart';

import '../../../support/build_app.dart';
import '../../../support/fake_language_repository.dart';
import '../../../support/fake_theme_repository.dart';
import '../../../support/open_screen.dart';

Finder inSheet(Finder finder) =>
    find.descendant(of: find.byType(BottomSheet), matching: finder);

void main() {
  group('opening', () {
    testWidgets('the gear of a top-level screen opens the Settings screen', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp(signedIn: true));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.widgetWithText(AppBar, 'Settings'), findsOneWidget);
    });

    testWidgets('hides the navigation bar and goes back', (tester) async {
      await tester.pumpWidget(buildApp(signedIn: true));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsNothing);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
    });
  });

  group('the list (ST-1)', () {
    testWidgets('has the sections and rows of the design', (tester) async {
      await openSettings(tester);

      for (final text in [
        'Account',
        'Alex',
        'alex@example.com',
        'Payments',
        'Pay schedule',
        'One payment a month',
        'Preferences',
        'Default currency',
        '₽ Russian ruble',
        'Theme',
        'System',
        'Light',
        'Dark',
        'Language',
        'English',
        'العربية',
        'Notifications',
        'Show notifications',
        'Not allowed yet',
        'Allow',
        'Remind me on pay days',
        'Data',
        'Categories',
        'Accounts',
        'Export CSV',
        'Import CSV',
        'Security',
        'App lock',
        'Money Scribe 0.1.0',
      ]) {
        expect(find.text(text), findsWidgets, reason: text);
      }
    });

    testWidgets('the switches start off', (tester) async {
      await openSettings(tester);

      // Remind on pay days, App lock and Fingerprint.
      final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
      expect(switches, hasLength(3));
      expect(switches.every((widget) => !widget.value), isTrue);
    });

    testWidgets('shows two payments when the account has them', (tester) async {
      await openSettings(
        tester,
        settings: const DemoSettings(paymentMode: PaymentMode.twoPayments),
      );

      expect(find.text('Two payments a month'), findsOneWidget);
    });

    testWidgets('says so when it could not load, and Try again loads', (
      tester,
    ) async {
      final demo = await openSettings(
        tester,
        settings: const DemoSettings(scenario: DemoScenario.noConnection),
      );

      expect(find.text("Couldn't load some settings."), findsOneWidget);
      expect(find.text('—'), findsWidgets);

      demo.update(const DemoSettings());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.text("Couldn't load some settings."), findsNothing);
      expect(find.text('One payment a month'), findsOneWidget);
    });
  });

  group('the theme', () {
    testWidgets('switches at once and is saved', (tester) async {
      final themes = FakeThemeRepository();
      await openSettings(tester, themeRepository: themes);
      ThemeMode themeMode() =>
          tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode!;
      expect(themeMode(), ThemeMode.system);

      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      expect(themeMode(), ThemeMode.dark);
      expect(themes.choice, ThemeChoice.dark);

      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();

      expect(themeMode(), ThemeMode.light);
    });
  });

  group('the language', () {
    testWidgets('switches at once and is saved', (tester) async {
      final languages = FakeLanguageRepository();
      await openSettings(tester, languageRepository: languages);

      await tester.tap(find.text('العربية'));
      await tester.pumpAndSettle();

      expect(languages.language, AppLanguage.arabic);
      expect(find.text('الإعدادات'), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.byType(SettingsScreen))),
        TextDirection.rtl,
      );
    });
  });

  group('the default currency (ST-9)', () {
    testWidgets('the row opens a sheet with the ten currencies', (
      tester,
    ) async {
      await openSettings(tester);

      await tester.tap(find.text('Default currency'));
      await tester.pumpAndSettle();

      for (final text in [
        '₽ Russian ruble',
        r'$ US dollar',
        '€ Euro',
        '£ British pound',
        '₺ Turkish lira',
        '¥ Japanese yen',
        'SAR Saudi riyal',
        'AED UAE dirham',
        'EGP Egyptian pound',
        'KWD Kuwaiti dinar',
      ]) {
        expect(inSheet(find.text(text)), findsOneWidget, reason: text);
      }
      expect(inSheet(find.byIcon(Icons.radio_button_checked)), findsOneWidget);
    });

    testWidgets('Done saves the chosen currency', (tester) async {
      await openSettings(tester);
      await tester.tap(find.text('Default currency'));
      await tester.pumpAndSettle();

      await tester.tap(inSheet(find.text(r'$ US dollar')));
      await tester.pumpAndSettle();
      await tester.tap(inSheet(find.text('Done')));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text(r'$ US dollar'), findsOneWidget);
      expect(find.text('₽ Russian ruble'), findsNothing);
    });

    testWidgets('Cancel keeps the currency', (tester) async {
      await openSettings(tester);
      await tester.tap(find.text('Default currency'));
      await tester.pumpAndSettle();

      await tester.tap(inSheet(find.text('€ Euro')));
      await tester.pumpAndSettle();
      await tester.tap(inSheet(find.text('Cancel')));
      await tester.pumpAndSettle();

      expect(find.text('₽ Russian ruble'), findsOneWidget);
    });

    testWidgets('a currency the server does not accept is put back', (
      tester,
    ) async {
      final demo = await openSettings(tester);
      demo.update(const DemoSettings(save: DemoSave.fails));
      await tester.tap(find.text('Default currency'));
      await tester.pumpAndSettle();

      await tester.tap(inSheet(find.text('€ Euro')));
      await tester.pumpAndSettle();
      await tester.tap(inSheet(find.text('Done')));
      await tester.pumpAndSettle();

      expect(
        find.text("Couldn't save. Check your connection."),
        findsOneWidget,
      );
      expect(find.text('₽ Russian ruble'), findsOneWidget);

      demo.update(const DemoSettings());
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('€ Euro'), findsOneWidget);
    });
  });

  group('the reminder', () {
    testWidgets('the switch turns on and stays on', (tester) async {
      await openSettings(tester);

      await tester.tap(
        find.widgetWithText(SwitchListTile, 'Remind me on pay days'),
      );
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<SwitchListTile>(
              find.widgetWithText(SwitchListTile, 'Remind me on pay days'),
            )
            .value,
        isTrue,
      );
    });
  });

  group('the rows that open a screen', () {
    testWidgets('Account opens the Account screen', (tester) async {
      await openSettings(tester);

      await tester.tap(find.text('Alex'));
      await tester.pumpAndSettle();

      expect(find.byType(AccountScreen), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('Pay schedule opens its screen, and a change comes back', (
      tester,
    ) async {
      await openSettings(tester);

      await tester.tap(find.text('Pay schedule'));
      await tester.pumpAndSettle();
      expect(find.byType(PayScheduleScreen), findsOneWidget);

      await tester.tap(find.text('Two payments'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.text('Two payments a month'), findsOneWidget);
    });

    testWidgets('Categories opens the categories', (tester) async {
      await openSettings(tester);

      await tester.tap(find.text('Categories'));
      await tester.pumpAndSettle();

      expect(find.byType(CategoriesScreen), findsOneWidget);
    });

    testWidgets('Accounts opens the accounts', (tester) async {
      await openSettings(tester);

      await tester.tap(find.text('Accounts'));
      await tester.pumpAndSettle();

      expect(find.byType(AccountsScreen), findsOneWidget);
    });

    testWidgets('Export CSV opens the sheet over the Settings', (tester) async {
      await openSettings(tester);

      await tester.tap(find.text('Export CSV'));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('Import CSV opens the import screen', (tester) async {
      await openSettings(tester);

      await tester.tap(find.text('Import CSV'));
      await tester.pumpAndSettle();

      expect(find.byType(CsvImportScreen), findsOneWidget);
    });
  });

  group('the app lock (AUTH-13)', () {
    testWidgets('turning it on asks for a PIN, and a PIN turns it on', (
      tester,
    ) async {
      await openSettings(tester);

      await tester.tap(find.widgetWithText(SwitchListTile, 'App lock'));
      await tester.pumpAndSettle();
      expect(find.byType(CreatePinScreen), findsOneWidget);

      for (final digit in [1, 2, 3, 4, 1, 2, 3, 4]) {
        await tester.tap(find.text('$digit'));
        await tester.pumpAndSettle();
      }

      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(
        tester
            .widget<SwitchListTile>(
              find.widgetWithText(SwitchListTile, 'App lock'),
            )
            .value,
        isTrue,
      );
    });

    testWidgets('going back from the PIN leaves the lock off', (tester) async {
      await openSettings(tester);
      await tester.tap(find.widgetWithText(SwitchListTile, 'App lock'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<SwitchListTile>(
              find.widgetWithText(SwitchListTile, 'App lock'),
            )
            .value,
        isFalse,
      );
    });

    testWidgets('turning it off again forgets the PIN', (tester) async {
      await openSettings(tester);
      await tester.tap(find.widgetWithText(SwitchListTile, 'App lock'));
      await tester.pumpAndSettle();
      for (final digit in [1, 2, 3, 4, 1, 2, 3, 4]) {
        await tester.tap(find.text('$digit'));
        await tester.pumpAndSettle();
      }

      await tester.tap(find.widgetWithText(SwitchListTile, 'App lock'));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<SwitchListTile>(
              find.widgetWithText(SwitchListTile, 'App lock'),
            )
            .value,
        isFalse,
      );
    });
  });

  testWidgets('is laid out right to left in Arabic', (tester) async {
    await openSettings(tester, language: AppLanguage.arabic);

    expect(find.text('الإعدادات'), findsOneWidget);
    expect(find.text('الحساب'), findsWidgets);
    expect(find.text('Money Scribe 0.1.0'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
