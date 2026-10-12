import 'package:money_scribe/features/settings/domain/theme_choice.dart';
import 'package:money_scribe/features/settings/domain/theme_repository.dart';

/// A theme repository that keeps the choice in memory.
class FakeThemeRepository implements ThemeRepository {
  new([this.choice = ThemeChoice.system]);

  ThemeChoice choice;

  @override
  ThemeChoice read() => choice;

  @override
  Future<void> write(ThemeChoice choice) async {
    this.choice = choice;
  }
}
