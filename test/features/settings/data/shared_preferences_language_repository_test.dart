import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/features/settings/data/shared_preferences_language_repository.dart';
import 'package:money_scribe/features/settings/domain/app_language.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/in_memory_preferences.dart';

void main() {
  test('nothing saved follows the system', () async {
    final repository = SharedPreferencesLanguageRepository(
      await openInMemoryPreferences(),
    );

    expect(repository.read(), AppLanguage.system);
  });

  test('a saved language is read back, also after a restart', () async {
    final repository = SharedPreferencesLanguageRepository(
      await openInMemoryPreferences(),
    );

    await repository.write(AppLanguage.arabic);

    final afterRestart = SharedPreferencesLanguageRepository(
      await SharedPreferencesWithCache.create(
        cacheOptions: const SharedPreferencesWithCacheOptions(),
      ),
    );
    expect(repository.read(), AppLanguage.arabic);
    expect(afterRestart.read(), AppLanguage.arabic);
  });

  test('choosing the system language clears the saved language', () async {
    final preferences = await openInMemoryPreferences({
      SharedPreferencesLanguageRepository.storageKey: 'ar',
    });
    final repository = SharedPreferencesLanguageRepository(preferences);

    await repository.write(AppLanguage.system);

    expect(repository.read(), AppLanguage.system);
    expect(
      preferences.containsKey(SharedPreferencesLanguageRepository.storageKey),
      isFalse,
    );
  });

  test('an unknown saved code follows the system', () async {
    final repository = SharedPreferencesLanguageRepository(
      await openInMemoryPreferences({
        SharedPreferencesLanguageRepository.storageKey: 'xx',
      }),
    );

    expect(repository.read(), AppLanguage.system);
  });
}
