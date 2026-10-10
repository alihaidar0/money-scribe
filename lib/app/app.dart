import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_scribe/app/router/app_router.dart';
import 'package:money_scribe/app/theme/app_theme.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/features/settings/application/language_controller.dart';

class MoneyScribeApp extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appTitle,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // `null` follows the device language.
      locale: ref.watch(languageControllerProvider).locale,
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
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
