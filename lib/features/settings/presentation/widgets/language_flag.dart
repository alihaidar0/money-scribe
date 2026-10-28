import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/features/settings/domain/app_language.dart';

/// The flag shown for a language: the flag of a country that speaks it, or a
/// globe for the language of the device. A new language gets its flag here.
String? languageFlagCountry(AppLanguage language) {
  return switch (language) {
    AppLanguage.system => null,
    AppLanguage.english => 'GB',
    AppLanguage.arabic => 'SA',
  };
}

/// The name of [language] as its speakers write it, so a person who cannot
/// read the language of the screen still finds theirs.
String languageName(AppLocalizations l10n, AppLanguage language) {
  return switch (language) {
    AppLanguage.system => l10n.languageSystem,
    AppLanguage.english => l10n.languageEnglish,
    AppLanguage.arabic => l10n.languageArabic,
  };
}

/// A small rounded flag for [language]. It only decorates: the name next to it
/// says the language, so it is left out of the semantics.
class LanguageFlag extends StatelessWidget {
  const new({
    required this.language,
    this.width = 36,
    this.height = 26,
    super.key,
  });

  final AppLanguage language;
  final double width;
  final double height;

  static const _radius = 6.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final country = languageFlagCountry(language);

    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_radius),
          // A thin line keeps a light flag from melting into the card.
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: SizedBox(
          width: width,
          height: height,
          child: country == null
              ? DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(_radius),
                  ),
                  child: Icon(
                    LucideIcons.globe,
                    size: height * 0.7,
                    color: scheme.onSurfaceVariant,
                  ),
                )
              : CountryFlag.fromCountryCode(
                  country,
                  theme: ImageTheme(
                    width: width,
                    height: height,
                    shape: const RoundedRectangle(_radius),
                  ),
                ),
        ),
      ),
    );
  }
}
