import 'package:money_scribe/features/settings/domain/app_language.dart';

/// Where the chosen app language is kept on the device.
abstract interface class LanguageRepository {
  AppLanguage read();

  Future<void> write(AppLanguage language);
}
