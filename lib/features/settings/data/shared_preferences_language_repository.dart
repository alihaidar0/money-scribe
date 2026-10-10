import 'package:money_scribe/features/settings/domain/app_language.dart';
import 'package:money_scribe/features/settings/domain/language_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesLanguageRepository implements LanguageRepository {
  const new(this._preferences);

  static const storageKey = 'app_language';

  final SharedPreferencesWithCache _preferences;

  @override
  AppLanguage read() {
    return AppLanguage.fromLanguageCode(_preferences.getString(storageKey));
  }

  @override
  Future<void> write(AppLanguage language) {
    final code = language.locale?.languageCode;
    return code == null
        ? _preferences.remove(storageKey)
        : _preferences.setString(storageKey, code);
  }
}
