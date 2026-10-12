import 'package:money_scribe/features/settings/domain/theme_choice.dart';
import 'package:money_scribe/features/settings/domain/theme_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesThemeRepository implements ThemeRepository {
  const new(this._preferences);

  static const storageKey = 'app_theme';

  final SharedPreferencesWithCache _preferences;

  @override
  ThemeChoice read() {
    return ThemeChoice.fromName(_preferences.getString(storageKey));
  }

  @override
  Future<void> write(ThemeChoice choice) {
    return choice == ThemeChoice.system
        ? _preferences.remove(storageKey)
        : _preferences.setString(storageKey, choice.name);
  }
}
