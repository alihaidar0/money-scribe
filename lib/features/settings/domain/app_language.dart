import 'dart:ui';

/// The language choices of the app: follow the device, or a fixed language.
enum AppLanguage {
  system,
  english,
  arabic;

  /// The locale to force, or `null` to follow the device.
  Locale? get locale {
    return switch (this) {
      AppLanguage.system => null,
      AppLanguage.english => const Locale('en'),
      AppLanguage.arabic => const Locale('ar'),
    };
  }

  /// The language for a stored code; anything unknown follows the device.
  static AppLanguage fromLanguageCode(String? code) {
    return values.firstWhere(
      (language) => language.locale?.languageCode == code,
      orElse: () => AppLanguage.system,
    );
  }
}
