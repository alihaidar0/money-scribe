import 'package:money_scribe/features/settings/domain/app_language.dart';
import 'package:money_scribe/features/settings/domain/language_repository.dart';

/// A language repository that keeps the choice in memory.
class FakeLanguageRepository implements LanguageRepository {
  new([this.language = AppLanguage.system]);

  AppLanguage language;

  @override
  AppLanguage read() => language;

  @override
  Future<void> write(AppLanguage language) async {
    this.language = language;
  }
}
