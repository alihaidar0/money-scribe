import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:money_scribe/app/app.dart';
import 'package:money_scribe/app/bloc/app_bloc_observer.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/environment/app_environment.dart';
import 'package:money_scribe/features/auth/data/fake/fake_app_lock_repository.dart';
import 'package:money_scribe/features/auth/data/fake/fake_auth_repository.dart';
import 'package:money_scribe/features/debts/data/fake/fake_debts_repository.dart';
import 'package:money_scribe/features/notifications/data/push_messaging_setup.dart';
import 'package:money_scribe/features/overview/data/fake/fake_overview_repository.dart';
import 'package:money_scribe/features/salary/data/fake/fake_fixed_items_repository.dart';
import 'package:money_scribe/features/salary/data/fake/fake_salary_repository.dart';
import 'package:money_scribe/features/settings/data/fake/fake_pay_schedule_repository.dart';
import 'package:money_scribe/features/settings/data/shared_preferences_language_repository.dart';
import 'package:money_scribe/features/transactions/data/fake/fake_accounts_repository.dart';
import 'package:money_scribe/features/transactions/data/fake/fake_categories_repository.dart';
import 'package:money_scribe/features/transactions/data/fake/fake_transactions_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Bloc.observer = const AppBlocObserver();
  final preferences = await SharedPreferencesWithCache.create(
    cacheOptions: const SharedPreferencesWithCacheOptions(),
  );
  final pushMessaging = await createPushMessagingRepository();

  // The server does not exist yet: the account and the pay schedule are fake
  // and live in memory. Connecting the server replaces them here and deletes
  // their `data/fake/` folders (`docs/architecture.md`).
  final demo = DemoController();

  runApp(
    MoneyScribeApp(
      languageRepository: SharedPreferencesLanguageRepository(preferences),
      pushMessagingRepository: pushMessaging,
      authRepository: FakeAuthRepository(demo: demo),
      appLockRepository: FakeAppLockRepository(),
      payScheduleRepository: FakePayScheduleRepository(demo: demo),
      overviewRepository: FakeOverviewRepository(demo: demo),
      salaryRepository: FakeSalaryRepository(demo: demo),
      fixedItemsRepository: FakeFixedItemsRepository(demo: demo),
      transactionsRepository: FakeTransactionsRepository(demo: demo),
      accountsRepository: FakeAccountsRepository(demo: demo),
      categoriesRepository: FakeCategoriesRepository(demo: demo),
      debtsRepository: FakeDebtsRepository(demo: demo),
      demo: demo,
      environment: AppEnvironment.current,
    ),
  );
}
