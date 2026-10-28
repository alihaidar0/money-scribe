import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:money_scribe/app/app.dart';
import 'package:money_scribe/app/bloc/app_bloc_observer.dart';
import 'package:money_scribe/core/challenge/challenge_view_factory.dart';
import 'package:money_scribe/core/challenge/turnstile_challenge_view_factory.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/device/platform_device_info_source.dart';
import 'package:money_scribe/core/device/time_zone_source.dart';
import 'package:money_scribe/core/environment/api_config.dart';
import 'package:money_scribe/core/environment/app_environment.dart';
import 'package:money_scribe/core/environment/turnstile_config.dart';
import 'package:money_scribe/core/network/data_changes.dart';
import 'package:money_scribe/core/network/dio_factory.dart';
import 'package:money_scribe/core/network/last_failure.dart';
import 'package:money_scribe/core/network/server_warm_up.dart';
import 'package:money_scribe/core/network/slow_request_monitor.dart';
import 'package:money_scribe/core/network/token_store.dart';
import 'package:money_scribe/core/storage/secure_value_store.dart';
import 'package:money_scribe/features/auth/data/biometric_signature_device_key_store.dart';
import 'package:money_scribe/features/auth/data/fake/fake_auth_repository.dart';
import 'package:money_scribe/features/auth/data/fake/fake_device_key_repository.dart';
import 'package:money_scribe/features/auth/data/local_auth_biometric_authenticator.dart';
import 'package:money_scribe/features/auth/data/remote/remote_auth.dart';
import 'package:money_scribe/features/auth/data/secure_app_lock_repository.dart';
import 'package:money_scribe/features/auth/domain/app_lock_repository.dart';
import 'package:money_scribe/features/auth/domain/auth_repository.dart';
import 'package:money_scribe/features/auth/domain/device_key_repository.dart';
import 'package:money_scribe/features/auth/presentation/demo_challenge_view_factory.dart';
import 'package:money_scribe/features/connection/data/monitored_server_activity.dart';
import 'package:money_scribe/features/debts/data/fake/fake_debts_repository.dart';
import 'package:money_scribe/features/debts/data/remote/remote_debts_repository.dart';
import 'package:money_scribe/features/notifications/data/push_messaging_setup.dart';
import 'package:money_scribe/features/overview/data/fake/fake_overview_repository.dart';
import 'package:money_scribe/features/overview/data/remote/remote_overview_repository.dart';
import 'package:money_scribe/features/reports/data/fake/fake_reports_repository.dart';
import 'package:money_scribe/features/reports/data/remote/remote_reports_repository.dart';
import 'package:money_scribe/features/salary/data/fake/fake_fixed_items_repository.dart';
import 'package:money_scribe/features/salary/data/fake/fake_salary_repository.dart';
import 'package:money_scribe/features/salary/data/remote/remote_fixed_items_repository.dart';
import 'package:money_scribe/features/salary/data/remote/remote_salary_repository.dart';
import 'package:money_scribe/features/sessions/data/fake/fake_sessions_repository.dart';
import 'package:money_scribe/features/sessions/data/remote/remote_sessions_repository.dart';
import 'package:money_scribe/features/settings/data/device/file_selector_csv_picker.dart';
import 'package:money_scribe/features/settings/data/device/share_sheet_csv_sharer.dart';
import 'package:money_scribe/features/settings/data/fake/fake_csv_transfer_repository.dart';
import 'package:money_scribe/features/settings/data/fake/fake_default_currency_repository.dart';
import 'package:money_scribe/features/settings/data/fake/fake_pay_schedule_repository.dart';
import 'package:money_scribe/features/settings/data/remote/remote_csv_transfer_repository.dart';
import 'package:money_scribe/features/settings/data/remote/remote_default_currency_repository.dart';
import 'package:money_scribe/features/settings/data/remote/remote_pay_schedule_repository.dart';
import 'package:money_scribe/features/settings/data/remote/remote_settings.dart';
import 'package:money_scribe/features/settings/data/shared_preferences_language_repository.dart';
import 'package:money_scribe/features/settings/data/shared_preferences_theme_repository.dart';
import 'package:money_scribe/features/settings/domain/language_repository.dart';
import 'package:money_scribe/features/transactions/data/fake/fake_accounts_repository.dart';
import 'package:money_scribe/features/transactions/data/fake/fake_categories_repository.dart';
import 'package:money_scribe/features/transactions/data/fake/fake_transactions_repository.dart';
import 'package:money_scribe/features/transactions/data/remote/remote_accounts_repository.dart';
import 'package:money_scribe/features/transactions/data/remote/remote_categories_repository.dart';
import 'package:money_scribe/features/transactions/data/remote/remote_transactions_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Bloc.observer = const AppBlocObserver();
  final preferences = await SharedPreferencesWithCache.create(
    cacheOptions: const SharedPreferencesWithCacheOptions(),
  );
  final pushMessaging = await createPushMessagingRepository();

  // A build with a server address (`API_BASE_URL`) has the real account; one
  // without keeps the fake one. Everything else is still fake and lives in
  // memory: connecting a feature replaces it here and deletes its `data/fake/`
  // folder (`docs/architecture.md`). A wrong address stops the app here, with
  // a message, rather than falling back to fake data.
  final apiConfig = ApiConfig.current;
  final demo = DemoController(fakeAccount: apiConfig == null);
  final languageRepository = SharedPreferencesLanguageRepository(preferences);
  final monitor = SlowRequestMonitor();
  final lastFailure = LastFailure();
  final (authRepository, deviceKeyRepository, apiDio) = await _createAccount(
    apiConfig: apiConfig,
    demo: demo,
    languageRepository: languageRepository,
    monitor: monitor,
    lastFailure: lastFailure,
  );
  // What this device saves on the server is announced, so the Overview and
  // the Reports load their figures again.
  final dataChanges = DataChanges();
  apiDio?.interceptors.add(DataChangesInterceptor(dataChanges));
  // The settings of the account are on the server when there is one.
  final settings = apiDio == null
      ? null
      : RemoteSettings.create(
          dio: apiDio,
          timeZone: const PlatformTimeZoneSource(),
          language: () => _accountLanguage(languageRepository),
          isSignedIn: () => authRepository.isSignedIn,
        );
  final payScheduleRepository = settings == null
      ? FakePayScheduleRepository(demo: demo)
      : RemotePayScheduleRepository(settings);
  final defaultCurrencyRepository = settings == null
      ? FakeDefaultCurrencyRepository(demo: demo)
      : RemoteDefaultCurrencyRepository(settings);
  // The fake accounts and categories ask the fake transactions whether they
  // are in use.
  final fakeTransactions = apiDio == null
      ? FakeTransactionsRepository(demo: demo)
      : null;
  final transactions =
      fakeTransactions ??
      RemoteTransactionsRepository.create(
        dio: apiDio!,
        paymentMode: () async => (await payScheduleRepository.load()).mode,
      );
  // The fake fixed items ask the fake salary which months are saved.
  final salary = apiDio == null
      ? FakeSalaryRepository(demo: demo)
      : RemoteSalaryRepository.create(dio: apiDio);
  // The app lock lives on the device. A signed-in person who has it on starts
  // on the lock screen, which is known before the first frame so no screen of
  // the app shows first.
  final appLock = SecureAppLockRepository(
    store: const PlatformSecureValueStore(),
    biometrics: LocalAuthBiometricAuthenticator(),
  );
  final startsLocked = authRepository.isSignedIn && await _isAppLockOn(appLock);
  // The free staging server sleeps after 15 minutes without a request: one
  // request at start wakes it, so it is often awake when the person signs in.
  // A production server does not sleep, so it is not asked.
  if (apiConfig != null && !AppEnvironment.current.isProduction) {
    unawaited(warmUpServer(createPlainDio(apiConfig, monitor: monitor)));
  }
  // An exported file stays in the private cache until the app it was shared
  // with has read it: the next start deletes it.
  const csvSharer = ShareSheetCsvSharer();
  unawaited(csvSharer.deleteLeftovers().catchError((Object _) {}));

  runApp(
    MoneyScribeApp(
      languageRepository: languageRepository,
      themeRepository: SharedPreferencesThemeRepository(preferences),
      pushMessagingRepository: pushMessaging,
      authRepository: authRepository,
      appLockRepository: appLock,
      deviceKeyRepository: deviceKeyRepository,
      startsLocked: startsLocked,
      payScheduleRepository: payScheduleRepository,
      defaultCurrencyRepository: defaultCurrencyRepository,
      accountLocaleRepository: settings,
      csvTransferRepository: apiDio == null
          ? FakeCsvTransferRepository(demo: demo)
          : RemoteCsvTransferRepository(
              dio: apiDio,
              picker: const FileSelectorCsvPicker(),
              sharer: csvSharer,
            ),
      overviewRepository: apiDio == null
          ? FakeOverviewRepository(demo: demo)
          : RemoteOverviewRepository.create(
              dio: apiDio,
              defaultCurrency: defaultCurrencyRepository.load,
              changes: dataChanges.stream,
            ),
      salaryRepository: salary,
      fixedItemsRepository: apiDio == null
          ? FakeFixedItemsRepository(demo: demo, salary: salary)
          : RemoteFixedItemsRepository.create(dio: apiDio),
      transactionsRepository: transactions,
      accountsRepository: apiDio == null
          ? FakeAccountsRepository(demo: demo, transactions: fakeTransactions)
          : RemoteAccountsRepository.create(dio: apiDio),
      categoriesRepository: apiDio == null
          ? FakeCategoriesRepository(demo: demo, transactions: fakeTransactions)
          : RemoteCategoriesRepository.create(dio: apiDio),
      debtsRepository: apiDio == null
          ? FakeDebtsRepository(
              demo: demo,
              defaultCurrency: defaultCurrencyRepository.load,
            )
          : RemoteDebtsRepository.create(
              dio: apiDio,
              defaultCurrency: defaultCurrencyRepository.load,
            ),
      sessionsRepository: apiDio == null
          ? FakeSessionsRepository(demo: demo)
          : RemoteSessionsRepository.create(dio: apiDio),
      reportsRepository: apiDio == null
          ? FakeReportsRepository(demo: demo)
          : RemoteReportsRepository.create(
              dio: apiDio,
              defaultCurrency: defaultCurrencyRepository.load,
              changes: dataChanges.stream,
            ),
      demo: demo,
      environment: AppEnvironment.current,
      challengeViewFactory: _createChallengeViewFactory(apiConfig),
      serverActivity: apiConfig == null
          ? null
          : MonitoredServerActivity(monitor),
      lastFailure: lastFailure,
    ),
  );
}

/// Whether the app lock is on. A storage that cannot be read counts as off:
/// the session tokens live in the same storage, so the person signs in again
/// anyway.
Future<bool> _isAppLockOn(AppLockRepository appLock) async {
  try {
    return await appLock.isEnabled();
  } on Exception {
    return false;
  }
}

/// The bot challenge of this build: Cloudflare Turnstile when there is a
/// server, else the demo button that goes with the fake account.
ChallengeViewFactory _createChallengeViewFactory(ApiConfig? apiConfig) {
  if (apiConfig == null) return const DemoChallengeViewFactory();
  return TurnstileChallengeViewFactory(
    siteKey: TurnstileConfig.current?.siteKey,
    baseUrl: apiConfig.baseUrl,
  );
}

/// The language the server is told: the server knows English and Arabic, any
/// other language is English.
String _accountLanguage(LanguageRepository languageRepository) {
  final locale =
      languageRepository.read().locale ?? PlatformDispatcher.instance.locale;
  return locale.languageCode == 'ar' ? 'ar' : 'en';
}

/// The account of this build, the fingerprint sign-in that goes with it, and
/// the HTTP client the other features build on: the real ones when there is a
/// server address, else the fake ones and no client.
Future<(AuthRepository, DeviceKeyRepository, Dio?)> _createAccount({
  required ApiConfig? apiConfig,
  required DemoController demo,
  required SharedPreferencesLanguageRepository languageRepository,
  required SlowRequestMonitor monitor,
  required LastFailure lastFailure,
}) async {
  if (apiConfig == null) {
    final auth = FakeAuthRepository(demo: demo);
    return (auth, FakeDeviceKeyRepository(demo: demo, auth: auth), null);
  }

  const secureStore = PlatformSecureValueStore();
  final remote = RemoteAuth.create(
    config: apiConfig,
    tokens: const SecureTokenStore(secureStore),
    device: PlatformDeviceInfoSource(secureStore),
    timeZone: const PlatformTimeZoneSource(),
    monitor: monitor,
    lastFailure: lastFailure,
    secureStore: secureStore,
    deviceKeyStore: BiometricSignatureDeviceKeyStore(
      // Only Android can vouch for a key with an attestation.
      attestsKeys: defaultTargetPlatform == TargetPlatform.android,
    ),
    language: () => _accountLanguage(languageRepository),
  );
  // The session of the last run, from the secure storage: no network, so the
  // app opens on the right screen. The server is asked in the background.
  await remote.repository.restore();
  unawaited(remote.repository.validateSession());
  return (remote.repository, remote.deviceKeys, remote.dio);
}
