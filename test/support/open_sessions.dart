import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/routing/app_routes.dart';
import 'package:money_scribe/features/auth/data/fake/fake_auth_repository.dart';
import 'package:money_scribe/features/sessions/domain/sessions_repository.dart';
import 'package:money_scribe/features/settings/domain/app_language.dart';

import 'build_app.dart';
import 'fake_language_repository.dart';
import 'fake_ticker.dart';
import 'open_screen.dart';

/// Opens [route] (the sessions or the security activity) of a signed-in
/// account, with the ticker the test moves and, when given, the sessions the
/// test brings.
Future<DemoController> openSessionsRoute(
  WidgetTester tester,
  String route, {
  DemoSettings settings = const DemoSettings(),
  AppLanguage language = AppLanguage.english,
  Size size = tallPhone,
  SessionsRepository Function(DemoController demo)? sessionsRepository,
  FakeTicker? ticker,
}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size;
  addTearDown(tester.view.reset);
  final demo = DemoController(initial: settings, latency: Duration.zero);
  await tester.pumpWidget(
    buildApp(
      demo: demo,
      languageRepository: FakeLanguageRepository(language),
      authRepository: FakeAuthRepository(demo: demo, signedIn: true),
      sessionsRepository: sessionsRepository?.call(demo),
      ticker: ticker,
    ),
  );
  await tester.pumpAndSettle();
  unawaited(
    GoRouter.of(tester.element(find.byType(Scaffold).first)).push(route),
  );
  await tester.pumpAndSettle();
  return demo;
}

Future<DemoController> openSessions(
  WidgetTester tester, {
  DemoSettings settings = const DemoSettings(),
  AppLanguage language = AppLanguage.english,
  SessionsRepository Function(DemoController demo)? sessionsRepository,
  FakeTicker? ticker,
}) {
  return openSessionsRoute(
    tester,
    AppRoutes.sessions,
    settings: settings,
    language: language,
    sessionsRepository: sessionsRepository,
    ticker: ticker,
  );
}

Future<DemoController> openSecurityActivity(
  WidgetTester tester, {
  DemoSettings settings = const DemoSettings(),
  AppLanguage language = AppLanguage.english,
  SessionsRepository Function(DemoController demo)? sessionsRepository,
}) {
  return openSessionsRoute(
    tester,
    AppRoutes.securityActivity,
    settings: settings,
    language: language,
    sessionsRepository: sessionsRepository,
  );
}
