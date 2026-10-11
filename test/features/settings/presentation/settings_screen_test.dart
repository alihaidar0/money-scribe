import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/features/settings/presentation/settings_screen.dart';

import '../../../support/build_app.dart';

void main() {
  testWidgets('the gear of a top-level screen opens the Settings screen', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp(signedIn: true));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Settings'), findsOneWidget);
  });

  testWidgets('the Settings screen hides the navigation bar and goes back', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp(signedIn: true));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsNothing);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
