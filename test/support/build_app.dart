import 'package:flutter/widgets.dart';
import 'package:money_scribe/app/app.dart';
import 'package:money_scribe/core/clipboard/text_clipboard.dart';
import 'package:money_scribe/core/environment/app_environment.dart';
import 'package:money_scribe/features/notifications/data/unavailable_push_messaging_repository.dart';
import 'package:money_scribe/features/notifications/domain/push_messaging_repository.dart';
import 'package:money_scribe/features/settings/domain/language_repository.dart';

import 'fake_language_repository.dart';
import 'fake_text_clipboard.dart';

/// The whole app with the language kept in memory instead of on the device,
/// staging as its environment, and push notifications unavailable unless a
/// [pushMessaging] is given.
Widget buildApp({
  LanguageRepository? languageRepository,
  PushMessagingRepository? pushMessaging,
  TextClipboard? clipboard,
  AppEnvironment environment = AppEnvironment.staging,
}) {
  return MoneyScribeApp(
    languageRepository: languageRepository ?? FakeLanguageRepository(),
    pushMessagingRepository:
        pushMessaging ?? const UnavailablePushMessagingRepository(),
    textClipboard: clipboard ?? FakeTextClipboard(),
    environment: environment,
  );
}
