import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/routing/app_routes.dart';
import 'package:money_scribe/features/settings/domain/app_language.dart';

import '../../../support/build_app.dart';
import '../../../support/fake_language_repository.dart';
import '../../../support/not_available_auth_repository.dart';

/// What the real server offers today: no deleting the account. The screen
/// says so instead of failing.
Future<void> _open(
  WidgetTester tester, {
  required String route,
  required bool signedIn,
  AppLanguage language = AppLanguage.english,
}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = const Size(412, 1800);
  addTearDown(tester.view.reset);
  final demo = DemoController(latency: Duration.zero);
  await tester.pumpWidget(
    buildApp(
      demo: demo,
      languageRepository: FakeLanguageRepository(language),
      authRepository: NotAvailableAuthRepository(
        demo: demo,
        signedIn: signedIn,
      ),
    ),
  );
  await tester.pumpAndSettle();
  GoRouter.of(tester.element(find.byType(Scaffold).first)).go(route);
  await tester.pumpAndSettle();
}

void main() {
  group('Delete account', () {
    testWidgets('says it is not available yet, and keeps the dialog', (
      tester,
    ) async {
      await _open(tester, route: AppRoutes.account, signedIn: true);
      await tester.tap(find.text('Delete account'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        'my password',
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(FilledButton, 'Delete account'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.text('Deleting your account is not available yet.'),
        findsOneWidget,
      );
      expect(find.text('Wrong password'), findsNothing);
    });
  });
}
