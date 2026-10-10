import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_scribe/core/preferences/preferences_provider.dart';
import 'package:money_scribe/features/settings/data/shared_preferences_language_repository.dart';
import 'package:money_scribe/features/settings/domain/app_language.dart';
import 'package:money_scribe/features/settings/domain/language_repository.dart';

final languageRepositoryProvider = Provider<LanguageRepository>(
  (ref) =>
      SharedPreferencesLanguageRepository(ref.watch(sharedPreferencesProvider)),
);

/// The app language: the saved choice, changed from the Settings screen.
class LanguageController extends Notifier<AppLanguage> {
  @override
  AppLanguage build() => ref.watch(languageRepositoryProvider).read();

  /// Switches the language at once, then saves the choice.
  Future<void> select(AppLanguage language) {
    state = language;
    return ref.read(languageRepositoryProvider).write(language);
  }
}

final languageControllerProvider =
    NotifierProvider<LanguageController, AppLanguage>(LanguageController.new);
