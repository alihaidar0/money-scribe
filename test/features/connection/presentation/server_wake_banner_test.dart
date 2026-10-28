import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:money_scribe/core/environment/app_environment.dart';
import 'package:money_scribe/features/auth/presentation/sign_in_screen.dart';
import 'package:money_scribe/features/connection/presentation/server_wake_banner.dart';
import 'package:money_scribe/features/settings/domain/app_language.dart';

import '../../../support/build_app.dart';
import '../../../support/fake_language_repository.dart';
import '../../../support/fake_server_activity.dart';

const _english =
    'The server is starting. This free staging server sleeps after 15 '
    'minutes without use, so the first request can take up to a minute. The '
    'production server does not sleep.';

Future<void> _open(
  WidgetTester tester, {
  FakeServerActivity? activity,
  AppEnvironment environment = AppEnvironment.staging,
  AppLanguage language = AppLanguage.english,
}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = const Size(412, 915);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    buildApp(
      languageRepository: FakeLanguageRepository(language),
      environment: environment,
      serverActivity: activity,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('in a staging build', () {
    testWidgets('says nothing while the server answers', (tester) async {
      await _open(tester, activity: FakeServerActivity());

      expect(find.byType(ServerWakeBanner), findsOneWidget);
      expect(find.text(_english), findsNothing);
    });

    testWidgets('says the server is starting while a request waits', (
      tester,
    ) async {
      final activity = FakeServerActivity();
      await _open(tester, activity: activity);

      activity.setSlow(value: true);
      await tester.pumpAndSettle();

      expect(find.text(_english), findsOneWidget);
      expect(find.byIcon(LucideIcons.hourglass), findsOneWidget);
    });

    testWidgets('goes away when the server answers', (tester) async {
      final activity = FakeServerActivity();
      await _open(tester, activity: activity);
      activity.setSlow(value: true);
      await tester.pumpAndSettle();

      activity.setSlow(value: false);
      await tester.pumpAndSettle();

      expect(find.text(_english), findsNothing);
    });

    testWidgets(
      'is there from the first frame when the server is already slow',
      (tester) async {
        await _open(tester, activity: FakeServerActivity(isSlow: true));

        expect(find.text(_english), findsOneWidget);
      },
    );

    testWidgets('never blocks the screen underneath', (tester) async {
      await _open(tester, activity: FakeServerActivity(isSlow: true));
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      // The banner sits over the top of the screen, where the back arrow is.
      await tester.tapAt(const Offset(40, 40));
      await tester.pumpAndSettle();

      expect(find.byType(SignInScreen), findsNothing);
    });

    testWidgets('is read out when it appears', (tester) async {
      final handle = tester.ensureSemantics();
      final activity = FakeServerActivity();
      await _open(tester, activity: activity);

      activity.setSlow(value: true);
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(find.text(_english)),
        matchesSemantics(label: _english, isLiveRegion: true),
      );
      handle.dispose();
    });

    testWidgets('is in Arabic too, and says the same things', (tester) async {
      await _open(
        tester,
        activity: FakeServerActivity(isSlow: true),
        language: AppLanguage.arabic,
      );

      expect(find.textContaining('الخادم قيد التشغيل'), findsOneWidget);
      expect(find.textContaining('15 دقيقة'), findsOneWidget);
      expect(find.textContaining('خادم الإنتاج فلا ينام'), findsOneWidget);
    });
  });

  group('where the server does not sleep or there is none', () {
    testWidgets('a production build never shows it', (tester) async {
      await _open(
        tester,
        activity: FakeServerActivity(isSlow: true),
        environment: AppEnvironment.production,
      );

      expect(find.byType(ServerWakeBanner), findsNothing);
      expect(find.text(_english), findsNothing);
    });

    testWidgets('a build with no server never shows it', (tester) async {
      await _open(tester);

      expect(find.byType(ServerWakeBanner), findsNothing);
    });
  });
}
