import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:money_scribe/app/demo/demo_handle.dart';
import 'package:money_scribe/app/router/app_router.dart';
import 'package:money_scribe/app/router/stream_listenable.dart';
import 'package:money_scribe/app/theme/app_theme.dart';
import 'package:money_scribe/core/clipboard/system_text_clipboard.dart';
import 'package:money_scribe/core/clipboard/text_clipboard.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/environment/app_environment.dart';
import 'package:money_scribe/core/environment/app_environment_scope.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/routing/app_routes.dart';
import 'package:money_scribe/core/time/clock.dart';
import 'package:money_scribe/core/time/ticker.dart';
import 'package:money_scribe/features/auth/domain/app_lock_repository.dart';
import 'package:money_scribe/features/auth/domain/auth_repository.dart';
import 'package:money_scribe/features/notifications/domain/push_messaging_repository.dart';
import 'package:money_scribe/features/overview/domain/overview_repository.dart';
import 'package:money_scribe/features/salary/domain/salary_repository.dart';
import 'package:money_scribe/features/settings/bloc/language_bloc.dart';
import 'package:money_scribe/features/settings/domain/language_repository.dart';
import 'package:money_scribe/features/settings/domain/pay_schedule_repository.dart';

/// The root of the app. It receives what the device and the server provide
/// (repositories, the environment) from `main`, so tests can pass fakes, and
/// hands them down: the environment through [AppEnvironmentScope], the
/// repositories with `RepositoryProvider`.
class MoneyScribeApp extends StatefulWidget {
  const new({
    required this.languageRepository,
    required this.pushMessagingRepository,
    required this.authRepository,
    required this.appLockRepository,
    required this.payScheduleRepository,
    required this.overviewRepository,
    required this.salaryRepository,
    required this.demo,
    required this.environment,
    this.textClipboard = const SystemTextClipboard(),
    this.ticker = const PeriodicTicker(),
    this.clock = const SystemClock(),
    super.key,
  });

  final LanguageRepository languageRepository;
  final PushMessagingRepository pushMessagingRepository;
  final AuthRepository authRepository;
  final AppLockRepository appLockRepository;
  final PayScheduleRepository payScheduleRepository;
  final OverviewRepository overviewRepository;
  final SalaryRepository salaryRepository;

  /// What the fake data pretends; changed by the demo panel.
  final DemoController demo;

  final AppEnvironment environment;
  final TextClipboard textClipboard;
  final Ticker ticker;
  final Clock clock;

  @override
  State<MoneyScribeApp> createState() => _MoneyScribeAppState();
}

class _MoneyScribeAppState extends State<MoneyScribeApp> {
  late final StreamListenable _signInChanges = StreamListenable(
    widget.authRepository.signedInChanges,
  );
  late final GoRouter _router = createAppRouter(
    auth: widget.authRepository,
    refreshListenable: _signInChanges,
  );

  @override
  void dispose() {
    _router.dispose();
    _signInChanges.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppEnvironmentScope(
      environment: widget.environment,
      child: MultiRepositoryProvider(
        providers: [
          RepositoryProvider.value(value: widget.pushMessagingRepository),
          RepositoryProvider.value(value: widget.textClipboard),
          RepositoryProvider.value(value: widget.authRepository),
          RepositoryProvider.value(value: widget.appLockRepository),
          RepositoryProvider.value(value: widget.payScheduleRepository),
          RepositoryProvider.value(value: widget.overviewRepository),
          RepositoryProvider.value(value: widget.salaryRepository),
          RepositoryProvider.value(value: widget.clock),
          RepositoryProvider.value(value: widget.ticker),
          RepositoryProvider.value(value: widget.demo),
        ],
        child: BlocProvider(
          create: (_) => LanguageBloc(repository: widget.languageRepository),
          child: _AppView(router: _router),
        ),
      ),
    );
  }
}

class _AppView extends StatelessWidget {
  const new({required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    final showDemoPanel = !AppEnvironmentScope.of(context).isProduction;
    final demo = context.read<DemoController>();

    // Only the locale is needed, so a language change rebuilds the app and
    // nothing else does.
    return BlocSelector<LanguageBloc, LanguageState, Locale?>(
      selector: (state) => state.language.locale,
      builder: (context, locale) => StreamBuilder<DemoTheme>(
        initialData: demo.settings.theme,
        stream: demo.changes.map((settings) => settings.theme).distinct(),
        builder: (context, theme) => MaterialApp.router(
          debugShowCheckedModeBanner: false,
          onGenerateTitle: (context) => context.l10n.appTitle,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: switch (theme.requireData) {
            DemoTheme.system => ThemeMode.system,
            DemoTheme.light => ThemeMode.light,
            DemoTheme.dark => ThemeMode.dark,
          },
          // `null` follows the device language.
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          // The font follows the language actually shown, which is only known
          // below the app, once the device language has been resolved.
          builder: (context, child) => Theme(
            data: AppTheme.forLocale(
              Theme.of(context),
              Localizations.localeOf(context),
            ),
            child: Stack(
              children: [
                child!,
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
