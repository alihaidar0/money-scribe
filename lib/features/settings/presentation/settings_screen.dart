import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/features/settings/application/language_controller.dart';
import 'package:money_scribe/features/settings/domain/app_language.dart';

class SettingsScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final language = ref.watch(languageControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          ListTile(
            title: Text(
              l10n.languageSectionTitle,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          RadioGroup<AppLanguage>(
            groupValue: language,
            onChanged: (value) {
              if (value != null) {
                unawaited(
                  ref.read(languageControllerProvider.notifier).select(value),
                );
              }
            },
            child: Column(
              children: [
                for (final option in AppLanguage.values)
                  RadioListTile<AppLanguage>(
                    value: option,
                    title: Text(_label(l10n, option)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _label(AppLocalizations l10n, AppLanguage language) {
    return switch (language) {
      AppLanguage.system => l10n.languageSystem,
      AppLanguage.english => l10n.languageEnglish,
      AppLanguage.arabic => l10n.languageArabic,
    };
  }
}
