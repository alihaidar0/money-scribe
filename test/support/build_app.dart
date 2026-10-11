import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_scribe/app/app.dart';
import 'package:money_scribe/app/environment/app_environment.dart';
import 'package:money_scribe/app/environment/app_environment_provider.dart';
import 'package:money_scribe/features/notifications/application/push_messaging_providers.dart';
import 'package:money_scribe/features/notifications/domain/push_messaging_repository.dart';
import 'package:money_scribe/features/settings/application/language_controller.dart';
import 'package:money_scribe/features/settings/domain/language_repository.dart';

import 'fake_language_repository.dart';

/// The whole app with the language kept in memory instead of on the device.
/// Push notifications are unavailable unless a [pushMessaging] is given.
Widget buildApp({
  LanguageRepository? languageRepository,
  PushMessagingRepository? pushMessaging,
  AppEnvironment? environment,
}) {
  return ProviderScope(
    overrides: [
      languageRepositoryProvider.overrideWithValue(
        languageRepository ?? FakeLanguageRepository(),
      ),
      if (pushMessaging != null)
        pushMessagingRepositoryProvider.overrideWithValue(pushMessaging),
      if (environment != null)
        appEnvironmentProvider.overrideWithValue(environment),
    ],
    child: const MoneyScribeApp(),
  );
}
