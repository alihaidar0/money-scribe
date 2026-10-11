import 'package:flutter/widgets.dart';
import 'package:money_scribe/app/app.dart';
import 'package:money_scribe/core/clipboard/text_clipboard.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/environment/app_environment.dart';
import 'package:money_scribe/core/time/ticker.dart';
import 'package:money_scribe/features/auth/data/fake/fake_app_lock_repository.dart';
import 'package:money_scribe/features/auth/data/fake/fake_auth_repository.dart';
import 'package:money_scribe/features/auth/domain/auth_repository.dart';
import 'package:money_scribe/features/notifications/data/unavailable_push_messaging_repository.dart';
import 'package:money_scribe/features/notifications/domain/push_messaging_repository.dart';
import 'package:money_scribe/features/settings/data/fake/fake_pay_schedule_repository.dart';
import 'package:money_scribe/features/settings/domain/language_repository.dart';

import 'fake_language_repository.dart';
import 'fake_text_clipboard.dart';
import 'fake_ticker.dart';

/// The whole app with the language kept in memory instead of on the device,
/// a fake account that answers at once and starts signed out (or signed in
/// with [signedIn]), a ticker that never moves, staging as its environment,
/// and push notifications unavailable unless a [pushMessaging] is given.
Widget buildApp({
  LanguageRepository? languageRepository,
  PushMessagingRepository? pushMessaging,
  TextClipboard? clipboard,
  AuthRepository? authRepository,
  DemoController? demo,
  Ticker? ticker,
  bool signedIn = false,
  AppEnvironment environment = AppEnvironment.staging,
}) {
  final demoController = demo ?? DemoController(latency: Duration.zero);

  return MoneyScribeApp(
    languageRepository: languageRepository ?? FakeLanguageRepository(),
    pushMessagingRepository:
        pushMessaging ?? const UnavailablePushMessagingRepository(),
    authRepository:
        authRepository ??
        FakeAuthRepository(demo: demoController, signedIn: signedIn),
    appLockRepository: FakeAppLockRepository(),
    payScheduleRepository: FakePayScheduleRepository(demo: demoController),
    demo: demoController,
    textClipboard: clipboard ?? FakeTextClipboard(),
    ticker: ticker ?? FakeTicker(),
    environment: environment,
  );
}
