import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:money_scribe/app/router/app_router.dart';
import 'package:money_scribe/app/theme/app_theme.dart';
import 'package:money_scribe/core/clipboard/system_text_clipboard.dart';
import 'package:money_scribe/core/clipboard/text_clipboard.dart';
import 'package:money_scribe/core/environment/app_environment.dart';
import 'package:money_scribe/core/environment/app_environment_scope.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/features/notifications/domain/push_messaging_repository.dart';
import 'package:money_scribe/features/settings/bloc/language_bloc.dart';
import 'package:money_scribe/features/settings/domain/language_repository.dart';

/// The root of the app. It receives what the device and the server provide
/// (repositories, the environment) from `main`, so tests can pass fakes, and
/// hands them down: the environment through [AppEnvironmentScope], the
/// repositories with `RepositoryProvider`.
class MoneyScribeApp extends StatefulWidget {
  const new({
    required this.languageRepository,
    required this.pushMessagingRepository,
    required this.environment,
    this.textClipboard = const SystemTextClipboard(),
    super.key,
  });

  final LanguageRepository languageRepository;
  final PushMessagingRepository pushMessagingRepository;
  final AppEnvironment environment;
  final TextClipboard textClipboard;

  @override
  State<MoneyScribeApp> createState() => _MoneyScribeAppState();
}

class _MoneyScribeAppState extends State<MoneyScribeApp> {
  final GoRouter _router = createAppRouter();

  @override
  void dispose() {
    _router.dispose();
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
    // Only the locale is needed, so a language change rebuilds the app and
    // nothing else does.
    return BlocSelector<LanguageBloc, LanguageState, Locale?>(
      selector: (state) => state.language.locale,
      builder: (context, locale) => MaterialApp.router(
        onGenerateTitle: (context) => context.l10n.appTitle,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
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
          child: child!,
        ),
        routerConfig: router,
      ),
    );
  }
}
