import 'package:flutter/widgets.dart';
import 'package:money_scribe/app/app.dart';
import 'package:money_scribe/core/clipboard/text_clipboard.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/environment/app_environment.dart';
import 'package:money_scribe/core/time/clock.dart';
import 'package:money_scribe/core/time/ticker.dart';
import 'package:money_scribe/features/auth/data/fake/fake_app_lock_repository.dart';
import 'package:money_scribe/features/auth/data/fake/fake_auth_repository.dart';
import 'package:money_scribe/features/auth/domain/auth_repository.dart';
import 'package:money_scribe/features/debts/data/fake/fake_debts_repository.dart';
import 'package:money_scribe/features/notifications/data/unavailable_push_messaging_repository.dart';
import 'package:money_scribe/features/notifications/domain/push_messaging_repository.dart';
import 'package:money_scribe/features/overview/data/fake/fake_overview_repository.dart';
import 'package:money_scribe/features/reports/data/fake/fake_reports_repository.dart';
import 'package:money_scribe/features/salary/data/fake/fake_fixed_items_repository.dart';
import 'package:money_scribe/features/salary/data/fake/fake_salary_repository.dart';
import 'package:money_scribe/features/settings/data/fake/fake_csv_transfer_repository.dart';
import 'package:money_scribe/features/settings/data/fake/fake_default_currency_repository.dart';
import 'package:money_scribe/features/settings/data/fake/fake_pay_schedule_repository.dart';
import 'package:money_scribe/features/settings/domain/language_repository.dart';
import 'package:money_scribe/features/settings/domain/theme_repository.dart';
import 'package:money_scribe/features/transactions/data/fake/fake_accounts_repository.dart';
import 'package:money_scribe/features/transactions/data/fake/fake_categories_repository.dart';
import 'package:money_scribe/features/transactions/data/fake/fake_transactions_repository.dart';

import 'fake_clock.dart';
import 'fake_language_repository.dart';
import 'fake_text_clipboard.dart';
import 'fake_theme_repository.dart';
import 'fake_ticker.dart';

/// The whole app with the language kept in memory instead of on the device,
/// a fake account that answers at once and starts signed out (or signed in
/// with [signedIn]), a ticker that never moves, staging as its environment,
/// and push notifications unavailable unless a [pushMessaging] is given.
Widget buildApp({
  LanguageRepository? languageRepository,
  ThemeRepository? themeRepository,
  PushMessagingRepository? pushMessaging,
  TextClipboard? clipboard,
  AuthRepository? authRepository,
  DemoController? demo,
  Ticker? ticker,
  Clock? clock,
  bool signedIn = false,
  AppEnvironment environment = AppEnvironment.staging,
}) {
  final demoController = demo ?? DemoController(latency: Duration.zero);
  final transactions = FakeTransactionsRepository(demo: demoController);

  return MoneyScribeApp(
    languageRepository: languageRepository ?? FakeLanguageRepository(),
    themeRepository: themeRepository ?? FakeThemeRepository(),
    pushMessagingRepository:
        pushMessaging ?? const UnavailablePushMessagingRepository(),
    authRepository:
        authRepository ??
        FakeAuthRepository(demo: demoController, signedIn: signedIn),
    appLockRepository: FakeAppLockRepository(),
    payScheduleRepository: FakePayScheduleRepository(demo: demoController),
    defaultCurrencyRepository: FakeDefaultCurrencyRepository(
      demo: demoController,
    ),
    csvTransferRepository: FakeCsvTransferRepository(demo: demoController),
    overviewRepository: FakeOverviewRepository(demo: demoController),
    salaryRepository: FakeSalaryRepository(demo: demoController),
    fixedItemsRepository: FakeFixedItemsRepository(demo: demoController),
    transactionsRepository: transactions,
    accountsRepository: FakeAccountsRepository(
      demo: demoController,
      transactions: transactions,
    ),
    categoriesRepository: FakeCategoriesRepository(
      demo: demoController,
      transactions: transactions,
    ),
    debtsRepository: FakeDebtsRepository(demo: demoController),
    reportsRepository: FakeReportsRepository(demo: demoController),
    demo: demoController,
    textClipboard: clipboard ?? FakeTextClipboard(),
    ticker: ticker ?? FakeTicker(),
    clock: clock ?? FixedClock(DateTime(2026, 10, 11)),
    environment: environment,
  );
}
