import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/app/app.dart';
import 'package:money_scribe/app/theme/app_theme.dart';
import 'package:money_scribe/features/overview/presentation/overview_screen.dart';

void main() {
  testWidgets('the app starts on the overview screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MoneyScribeApp()));

    expect(find.byType(OverviewScreen), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);
  });

  testWidgets('the app follows the system between the light and dark themes', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: MoneyScribeApp()));

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));

    expect(app.theme, AppTheme.light);
    expect(app.darkTheme, AppTheme.dark);
    expect(app.themeMode, ThemeMode.system);
  });
}
