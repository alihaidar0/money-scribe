import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/features/settings/application/language_controller.dart';
import 'package:money_scribe/features/settings/domain/app_language.dart';

import '../../../support/fake_language_repository.dart';

void main() {
  ProviderContainer createContainer(FakeLanguageRepository repository) {
    final container = ProviderContainer(
      overrides: [languageRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('starts with the saved language', () {
    final container = createContainer(
      FakeLanguageRepository(AppLanguage.arabic),
    );

    expect(container.read(languageControllerProvider), AppLanguage.arabic);
  });

  test('selecting a language switches to it and saves it', () async {
    final repository = FakeLanguageRepository();
    final container = createContainer(repository);

    await container
        .read(languageControllerProvider.notifier)
        .select(AppLanguage.english);

    expect(container.read(languageControllerProvider), AppLanguage.english);
    expect(repository.language, AppLanguage.english);
  });
}
