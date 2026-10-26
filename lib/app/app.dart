import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:money_scribe/app/app_lock_gate.dart';
import 'package:money_scribe/app/demo/demo_handle.dart';
import 'package:money_scribe/app/device_key_sync.dart';
import 'package:money_scribe/app/push_token_cleanup.dart';
import 'package:money_scribe/app/router/app_router.dart';
import 'package:money_scribe/app/router/stream_listenable.dart';
import 'package:money_scribe/app/theme/app_theme.dart';
import 'package:money_scribe/core/challenge/challenge_view_factory.dart';
import 'package:money_scribe/core/clipboard/system_text_clipboard.dart';
import 'package:money_scribe/core/clipboard/text_clipboard.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/environment/app_environment.dart';
import 'package:money_scribe/core/environment/app_environment_scope.dart';
import 'package:money_scribe/core/formatting/western_digits.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/network/last_failure.dart';
import 'package:money_scribe/core/routing/app_routes.dart';
import 'package:money_scribe/core/time/clock.dart';
import 'package:money_scribe/core/time/ticker.dart';
import 'package:money_scribe/core/widgets/last_failure_scope.dart';
import 'package:money_scribe/features/auth/domain/app_lock_repository.dart';
import 'package:money_scribe/features/auth/domain/app_lock_session.dart';
import 'package:money_scribe/features/auth/domain/auth_repository.dart';
import 'package:money_scribe/features/auth/domain/device_key_repository.dart';
import 'package:money_scribe/features/connection/bloc/server_wake_bloc.dart';
import 'package:money_scribe/features/connection/domain/server_activity.dart';
import 'package:money_scribe/features/connection/presentation/server_wake_banner.dart';
import 'package:money_scribe/features/debts/domain/debts_repository.dart';
import 'package:money_scribe/features/notifications/domain/push_messaging_repository.dart';
import 'package:money_scribe/features/overview/domain/overview_repository.dart';
import 'package:money_scribe/features/reports/domain/reports_repository.dart';
import 'package:money_scribe/features/salary/domain/fixed_items_repository.dart';
import 'package:money_scribe/features/salary/domain/salary_repository.dart';
import 'package:money_scribe/features/settings/bloc/language_bloc.dart';
import 'package:money_scribe/features/settings/bloc/theme_bloc.dart';
import 'package:money_scribe/features/settings/domain/account_locale_repository.dart';
import 'package:money_scribe/features/settings/domain/csv_transfer_repository.dart';
import 'package:money_scribe/features/settings/domain/default_currency_repository.dart';
import 'package:money_scribe/features/settings/domain/language_repository.dart';
import 'package:money_scribe/features/settings/domain/pay_schedule_repository.dart';
import 'package:money_scribe/features/settings/domain/theme_choice.dart';
import 'package:money_scribe/features/settings/domain/theme_repository.dart';
import 'package:money_scribe/features/transactions/domain/accounts_repository.dart';
import 'package:money_scribe/features/transactions/domain/categories_repository.dart';
import 'package:money_scribe/features/transactions/domain/transactions_repository.dart';

/// The root of the app. It receives what the device and the server provide
/// (repositories, the environment) from `main`, so tests can pass fakes, and
/// hands them down: the environment through [AppEnvironmentScope], the
/// repositories with `RepositoryProvider`.
class MoneyScribeApp extends StatefulWidget {
  const new({
    required this.languageRepository,
    required this.themeRepository,
    required this.pushMessagingRepository,
    required this.authRepository,
    required this.appLockRepository,
    required this.deviceKeyRepository,
    required this.payScheduleRepository,
    required this.defaultCurrencyRepository,
    required this.csvTransferRepository,
    required this.overviewRepository,
    required this.salaryRepository,
    required this.fixedItemsRepository,
    required this.transactionsRepository,
    required this.accountsRepository,
    required this.categoriesRepository,
    required this.debtsRepository,
    required this.reportsRepository,
    required this.demo,
    required this.environment,
    required this.challengeViewFactory,
    this.startsLocked = false,
    this.accountLocaleRepository,
    this.serverActivity,
    this.lastFailure,
    this.textClipboard = const SystemTextClipboard(),
    this.ticker = const PeriodicTicker(),
    this.clock = const SystemClock(),
    super.key,
  });

  final LanguageRepository languageRepository;
  final ThemeRepository themeRepository;
  final PushMessagingRepository pushMessagingRepository;
  final AuthRepository authRepository;
  final AppLockRepository appLockRepository;
  final DeviceKeyRepository deviceKeyRepository;
  final PayScheduleRepository payScheduleRepository;
  final DefaultCurrencyRepository defaultCurrencyRepository;
  final CsvTransferRepository csvTransferRepository;
  final OverviewRepository overviewRepository;
  final SalaryRepository salaryRepository;
  final FixedItemsRepository fixedItemsRepository;
  final TransactionsRepository transactionsRepository;
  final AccountsRepository accountsRepository;
  final CategoriesRepository categoriesRepository;
  final DebtsRepository debtsRepository;
  final ReportsRepository reportsRepository;

  /// What the fake data pretends; changed by the demo panel.
  final DemoController demo;

  final AppEnvironment environment;

  /// How fast the server answers. `null` for a build with no server. Staging
  /// builds use it to tell the person the free server is starting.
  final ServerActivity? serverActivity;

  /// What the latest failed answer of the server said, for the failure
  /// screens. `null` for a build with no server: there is nothing to show.
  final LastFailure? lastFailure;

  /// Tells the server the language of the app when it changes; `null` in a
  /// build with no server.
  final AccountLocaleRepository? accountLocaleRepository;

  /// Shows the bot challenge the server may ask for at sign-in.
  final ChallengeViewFactory challengeViewFactory;

  /// Whether the app opens on the lock screen: a person is signed in and has
  /// the app lock on. Known before the first frame, so no screen of the app
  /// shows first.
  final bool startsLocked;

  final TextClipboard textClipboard;
  final Ticker ticker;
  final Clock clock;

  @override
  State<MoneyScribeApp> createState() => _MoneyScribeAppState();
}

class _MoneyScribeAppState extends State<MoneyScribeApp> {
  late final PushTokenCleanup _pushTokenCleanup;
  late final LastFailure _lastFailure = widget.lastFailure ?? LastFailure();
  late final AppLockGate _lockGate;
  late final DeviceKeySync _deviceKeySync;

  @override
  void initState() {
    super.initState();
    WesternDigits.useInDateFormats();
    // A signed-out device keeps no push token. It listens from the start, so
    // it is built here and not on first use.
    _pushTokenCleanup = PushTokenCleanup(
      auth: widget.authRepository,
      push: widget.pushMessagingRepository,
    );
    // A fingerprint key the server no longer knows is taken off the phone
    // after each sign-in.
    _deviceKeySync = DeviceKeySync(
      auth: widget.authRepository,
      deviceKeys: widget.deviceKeyRepository,
    );
    // The lock watches the app move to the background, and locks it after the
    // time the person chose.
    _lockGate = AppLockGate(
      auth: widget.authRepository,
      repository: widget.appLockRepository,
      clock: widget.clock,
      locked: widget.startsLocked,
    )..start();
  }

  late final StreamListenable _signInChanges = StreamListenable(
    widget.authRepository.signedInChanges,
  );
  late final StreamListenable _lockChanges = StreamListenable(
    _lockGate.changes,
  );
  late final GoRouter _router = createAppRouter(
    auth: widget.authRepository,
    lock: _lockGate,
    refreshListenable: Listenable.merge([_signInChanges, _lockChanges]),
  );

  @override
  void dispose() {
    _router.dispose();
    _signInChanges.dispose();
    _lockChanges.dispose();
    unawaited(_lockGate.dispose());
    unawaited(_pushTokenCleanup.dispose());
    unawaited(_deviceKeySync.dispose());
    super.dispose();
  }

  /// Whether to tell the person that the server is starting: only staging
  /// builds have a server that sleeps, and only a build with a server.
  bool get _showServerNotice =>
      widget.serverActivity != null && !widget.environment.isProduction;

  @override
  Widget build(BuildContext context) {
    return AppEnvironmentScope(
      environment: widget.environment,
      child: LastFailureScope(
        failure: _lastFailure,
        child: MultiRepositoryProvider(
          providers: [
            RepositoryProvider.value(value: widget.pushMessagingRepository),
            RepositoryProvider.value(value: widget.textClipboard),
            RepositoryProvider.value(value: widget.authRepository),
            RepositoryProvider.value(value: widget.appLockRepository),
            RepositoryProvider.value(value: widget.deviceKeyRepository),
            RepositoryProvider<AppLockSession>.value(value: _lockGate),
            RepositoryProvider.value(value: widget.payScheduleRepository),
            RepositoryProvider.value(value: widget.defaultCurrencyRepository),
            RepositoryProvider.value(value: widget.csvTransferRepository),
            RepositoryProvider.value(value: widget.overviewRepository),
            RepositoryProvider.value(value: widget.salaryRepository),
            RepositoryProvider.value(value: widget.fixedItemsRepository),
            RepositoryProvider.value(value: widget.transactionsRepository),
            RepositoryProvider.value(value: widget.accountsRepository),
            RepositoryProvider.value(value: widget.categoriesRepository),
            RepositoryProvider.value(value: widget.debtsRepository),
            RepositoryProvider.value(value: widget.reportsRepository),
            RepositoryProvider.value(value: widget.clock),
            RepositoryProvider.value(value: widget.ticker),
            RepositoryProvider.value(value: widget.demo),
            RepositoryProvider.value(value: widget.challengeViewFactory),
          ],
          child: MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) => LanguageBloc(
                  repository: widget.languageRepository,
                  accountLocale: widget.accountLocaleRepository,
                ),
              ),
              BlocProvider(
                create: (_) => ThemeBloc(repository: widget.themeRepository),
              ),
              if (_showServerNotice)
                BlocProvider(
                  create: (_) =>
                      ServerWakeBloc(activity: widget.serverActivity!)
                        ..add(const ServerWakeStarted()),
                ),
            ],
            child: _AppView(
              router: _router,
              showServerNotice: _showServerNotice,
            ),
          ),
        ),
      ),
    );
  }
}

class _AppView extends StatelessWidget {
  const new({required this.router, required this.showServerNotice});

  final GoRouter router;
  final bool showServerNotice;

  @override
  Widget build(BuildContext context) {
    final showDemoPanel = !AppEnvironmentScope.of(context).isProduction;

    // Only the locale and the theme are needed, so changing one of them
    // rebuilds the app and nothing else does.
    return BlocSelector<LanguageBloc, LanguageState, Locale?>(
      selector: (state) => state.language.locale,
      builder: (context, locale) =>
          BlocSelector<ThemeBloc, ThemeState, ThemeChoice>(
            selector: (state) => state.choice,
            builder: (context, theme) => MaterialApp.router(
              debugShowCheckedModeBanner: false,
              onGenerateTitle: (context) => context.l10n.appTitle,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: switch (theme) {
                ThemeChoice.system => ThemeMode.system,
                ThemeChoice.light => ThemeMode.light,
                ThemeChoice.dark => ThemeMode.dark,
              },
              // `null` follows the device language.
              locale: locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              // The font follows the language actually shown, which is only
              // known below the app, once the device language has been
              // resolved.
              builder: (context, child) => Theme(
                data: AppTheme.forLocale(
                  Theme.of(context),
                  Localizations.localeOf(context),
                ),
                child: Stack(
                  children: [
                    child!,
                    if (showServerNotice) const ServerWakeBanner(),
                    if (showDemoPanel) DemoHandle(onPressed: _openDemoPanel),
                  ],
                ),
              ),
              routerConfig: router,
            ),
          ),
    );
  }

  void _openDemoPanel() {
    // The top screen, which can be one pushed on top of another location.
    final top = router.routerDelegate.currentConfiguration.last.matchedLocation;
    if (top != AppRoutes.demo) {
      unawaited(router.push<void>(AppRoutes.demo));
    }
  }
}
