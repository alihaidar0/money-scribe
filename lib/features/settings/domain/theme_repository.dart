import 'package:money_scribe/features/settings/domain/theme_choice.dart';

/// Where the chosen theme is kept on the device.
abstract interface class ThemeRepository {
  ThemeChoice read();

  Future<void> write(ThemeChoice choice);
}
