import 'package:flutter/widgets.dart';
import 'package:money_scribe/app/app.dart';
import 'package:money_scribe/core/challenge/challenge_view_factory.dart';
import 'package:money_scribe/core/clipboard/text_clipboard.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/environment/app_environment.dart';
import 'package:money_scribe/core/time/clock.dart';
import 'package:money_scribe/core/time/ticker.dart';
import 'package:money_scribe/features/auth/data/fake/fake_auth_repository.dart';
import 'package:money_scribe/features/auth/data/fake/fake_device_key_repository.dart';
import 'package:money_scribe/features/auth/domain/app_lock_repository.dart';
import 'package:money_scribe/features/auth/domain/auth_repository.dart';
import 'package:money_scribe/features/auth/domain/device_key_repository.dart';
import 'package:money_scribe/features/auth/presentation/demo_challenge_view_factory.dart';
import 'package:money_scribe/features/connection/domain/server_activity.dart';
import 'package:money_scribe/features/debts/data/fake/fake_debts_repository.dart';
import 'package:money_scribe/features/debts/domain/debts_repository.dart';
import 'package:money_scribe/features/notifications/data/unavailable_push_messaging_repository.dart';
import 'package:money_scribe/features/notifications/domain/push_messaging_repository.dart';
import 'package:money_scribe/features/overview/data/fake/fake_overview_repository.dart';
import 'package:money_scribe/features/reports/data/fake/fake_reports_repository.dart';
import 'package:money_scribe/features/salary/data/fake/fake_fixed_items_repository.dart';
import 'package:money_scribe/features/salary/data/fake/fake_salary_repository.dart';
import 'package:money_scribe/features/salary/domain/fixed_items_repository.dart';
import 'package:money_scribe/features/salary/domain/salary_repository.dart';
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
import 'instant_app_lock_repository.dart';

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
  AppLockRepository? appLockRepository,
  DeviceKeyRepository? deviceKeyRepository,
  DemoController? demo,
  SalaryRepository? salaryRepository,
  FixedItemsRepository? fixedItemsRepository,
  DebtsRepository? debtsRepository,
  Ticker? ticker,
  Clock? clock,
  bool signedIn = false,
  bool locked = false,
  AppEnvironment environment = AppEnvironment.staging,
  ServerActivity? serverActivity,
  ChallengeViewFactory? challengeViewFactory,
}) {
  final demoController = demo ?? DemoController(latency: Duration.zero);
  final transactions = FakeTransactionsRepository(demo: demoController);
  final salary = salaryRepository ?? FakeSalaryRepository(demo: demoController);
  final account =
      authRepository ??
      FakeAuthRepository(demo: demoController, signedIn: signedIn);

  return MoneyScribeApp(
    languageRepository: languageRepository ?? FakeLanguageRepository(),
    themeRepository: themeRepository ?? FakeThemeRepository(),
    pushMessagingRepository:
        pushMessaging ?? const UnavailablePushMessagingRepository(),
    authRepository: account,
    deviceKeyRepository:
        deviceKeyRepository ??
        FakeDeviceKeyRepository(
          demo: demoController,
          // A test that brings its own account has no fake to follow.
          auth: account is FakeAuthRepository
              ? account
              : FakeAuthRepository(demo: demoController),
        ),
    challengeViewFactory:
        challengeViewFactory ?? const DemoChallengeViewFactory(),
    appLockRepository:
        appLockRepository ??
        InstantAppLockRepository(deviceHasFingerprint: false),
    startsLocked: locked,
    payScheduleRepository: FakePayScheduleRepository(demo: demoController),
    defaultCurrencyRepository: FakeDefaultCurrencyRepository(
      demo: demoController,
    ),
    csvTransferRepository: FakeCsvTransferRepository(demo: demoController),
    overviewRepository: FakeOverviewRepository(demo: demoController),
    salaryRepository: salary,
    fixedItemsRepository:
        fixedItemsRepository ??
        FakeFixedItemsRepository(demo: demoController, salary: salary),
    transactionsRepository: transactions,
    accountsRepository: FakeAccountsRepository(
      demo: demoController,
      transactions: transactions,
    ),
    categoriesRepository: FakeCategoriesRepository(
      demo: demoController,
      transactions: transactions,
    ),
    debtsRepository:
        debtsRepository ?? FakeDebtsRepository(demo: demoController),
    reportsRepository: FakeReportsRepository(demo: demoController),
    demo: demoController,
    textClipboard: clipboard ?? FakeTextClipboard(),
    ticker: ticker ?? FakeTicker(),
    clock: clock ?? FixedClock(DateTime(2026, 10, 11)),
    environment: environment,
    serverActivity: serverActivity,
  );
}
