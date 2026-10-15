import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/app/theme/app_theme.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/features/overview/data/fake/fake_overview_repository.dart';
import 'package:money_scribe/features/overview/domain/debt_choice.dart';
import 'package:money_scribe/features/overview/domain/overview_repository.dart';
import 'package:money_scribe/features/overview/presentation/widgets/debt_choice_sheet.dart';

DebtChoice? _chosen;

Future<DemoController> _openSheet(
  WidgetTester tester,
  DemoSettings settings,
) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = const Size(412, 915);
  addTearDown(tester.view.reset);
  final demo = DemoController(initial: settings, latency: Duration.zero);
  _chosen = null;
  await tester.pumpWidget(
    RepositoryProvider<OverviewRepository>.value(
      value: FakeOverviewRepository(demo: demo),
      child: MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async =>
                  _chosen = await showDebtChoiceSheet(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return demo;
}

void main() {
  testWidgets('returns the chosen debt', (tester) async {
    await _openSheet(tester, const DemoSettings());

    await tester.tap(find.text('Maria'));
    await tester.pumpAndSettle();

    expect(_chosen?.person, 'Maria');
    expect(find.text('Choose a debt'), findsNothing);
  });

  testWidgets('returns nothing when cancelled', (tester) async {
    await _openSheet(tester, const DemoSettings());

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(_chosen, isNull);
    expect(find.text('Choose a debt'), findsNothing);
  });

  testWidgets('says so when there is no debt to repay', (tester) async {
    await _openSheet(tester, const DemoSettings(scenario: DemoScenario.empty));

    expect(find.text('No open debts.'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('no connection offers Try again, which loads the debts', (
    tester,
  ) async {
    final demo = await _openSheet(
      tester,
      const DemoSettings(scenario: DemoScenario.noConnection),
    );
    expect(find.text('No connection'), findsOneWidget);

    demo.update(const DemoSettings());
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('Sam'), findsOneWidget);
  });

  testWidgets('a server failure offers Try again', (tester) async {
    await _openSheet(tester, const DemoSettings(scenario: DemoScenario.error));

    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });
}
