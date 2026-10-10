import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_scribe/app/app.dart';
import 'package:money_scribe/features/settings/application/language_controller.dart';
import 'package:money_scribe/features/settings/domain/language_repository.dart';

import 'fake_language_repository.dart';

/// The whole app with the language kept in memory instead of on the device.
Widget buildApp({LanguageRepository? languageRepository}) {
  return ProviderScope(
    overrides: [
      languageRepositoryProvider.overrideWithValue(
        languageRepository ?? FakeLanguageRepository(),
      ),
    ],
    child: const MoneyScribeApp(),
  );
}
