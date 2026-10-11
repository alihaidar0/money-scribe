import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/routing/app_routes.dart';
import 'package:money_scribe/features/auth/data/fake/fake_auth_repository.dart';
import 'package:money_scribe/features/auth/presentation/sign_in_screen.dart';
import 'package:money_scribe/features/auth/presentation/welcome_screen.dart';
import 'package:money_scribe/features/overview/presentation/overview_screen.dart';
import 'package:money_scribe/features/salary/presentation/salary_screen.dart';

import '../../support/build_app.dart';

GoRouter _router(WidgetTester tester) {
  return GoRouter.of(tester.element(find.byType(Scaffold).first));
}

Future<void> _go(WidgetTester tester, String path) async {
  _router(tester).go(path);
  await tester.pumpAndSettle();
}

void main() {
  group('signed out', () {
    testWidgets('the app opens on the Welcome screen', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.byType(WelcomeScreen), findsOneWidget);
    });

    testWidgets('the screens of the app lead back to Welcome', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      for (final path in [
        AppRoutes.overview,
        AppRoutes.salary,
        AppRoutes.settings,
        AppRoutes.paySetup,
      ]) {
        await _go(tester, path);
        expect(find.byType(WelcomeScreen), findsOneWidget, reason: path);
      }
    });

    testWidgets('the sign-in screens open', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await _go(tester, AppRoutes.signIn);

      expect(find.byType(SignInScreen), findsOneWidget);
    });
  });

  group('signed in', () {
    testWidgets('the app opens on the Overview', (tester) async {
      await tester.pumpWidget(buildApp(signedIn: true));
      await tester.pumpAndSettle();

      expect(find.byType(OverviewScreen), findsOneWidget);
    });

    testWidgets('the sign-in screens lead to the Overview', (tester) async {
      await tester.pumpWidget(buildApp(signedIn: true));
      await tester.pumpAndSettle();

      for (final path in AppRoutes.signedOutOnly) {
        await _go(tester, path);
        expect(find.byType(OverviewScreen), findsOneWidget, reason: path);
      }
    });

    testWidgets('the screens of the app open', (tester) async {
      await tester.pumpWidget(buildApp(signedIn: true));
      await tester.pumpAndSettle();

      await _go(tester, AppRoutes.salary);

      expect(find.byType(SalaryScreen), findsOneWidget);
    });

    testWidgets('signing out leads to the Welcome screen', (tester) async {
      final demo = DemoController(latency: Duration.zero);
      final auth = FakeAuthRepository(demo: demo, signedIn: true);
      await tester.pumpWidget(buildApp(demo: demo, authRepository: auth));
      await tester.pumpAndSettle();
      expect(find.byType(OverviewScreen), findsOneWidget);

      await auth.signOut();
      await tester.pumpAndSettle();

      expect(find.byType(WelcomeScreen), findsOneWidget);
    });
  });
}
