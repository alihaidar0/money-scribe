import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';
import 'package:money_scribe/core/widgets/skeleton.dart';
import 'package:money_scribe/features/settings/domain/app_language.dart';
import 'package:money_scribe/features/settings/presentation/pay_schedule_screen.dart';
import 'package:money_scribe/features/settings/presentation/settings_screen.dart';

import '../../../support/open_screen.dart';

Future<DemoController> openPaySchedule(
  WidgetTester tester, {
  DemoSettings settings = const DemoSettings(),
  AppLanguage language = AppLanguage.english,
}) async {
  final demo = await openSettings(
    tester,
    settings: settings,
    language: language,
  );
  await tester.tap(
    find.text(language == AppLanguage.arabic ? 'جدول الدفع' : 'Pay schedule'),
  );
  await tester.pumpAndSettle();
  return demo;
}

void main() {
  testWidgets('shows the segments, the reminder, the note and Save', (
    tester,
  ) async {
    await openPaySchedule(tester);

    expect(find.byType(PayScheduleScreen), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Pay schedule'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('Payments per month'), findsOneWidget);
    expect(find.text('One payment'), findsOneWidget);
    expect(find.text('Two payments'), findsOneWidget);
    expect(find.text('Remind me on pay days'), findsOneWidget);
    expect(
      find.text(
        'This sets how new months are created. To correct a saved month, '
        'open it from Salary history.',
      ),
      findsOneWidget,
    );
    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets('one payment hides the pay days', (tester) async {
    await openPaySchedule(tester);

    expect(find.text('First payment is paid on day'), findsNothing);
    expect(find.text('Second payment is paid on day'), findsNothing);
  });

  testWidgets('two payments show the pay days, 20 and 5', (tester) async {
    await openPaySchedule(
      tester,
      settings: const DemoSettings(paymentMode: PaymentMode.twoPayments),
    );

    expect(find.text('First payment is paid on day'), findsOneWidget);
    expect(find.text('Second payment is paid on day'), findsOneWidget);
    expect(find.text('of the next month'), findsOneWidget);
    expect(find.text('20'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('choosing two payments reveals the pay days', (tester) async {
    await openPaySchedule(tester);

    await tester.tap(find.text('Two payments'));
    await tester.pumpAndSettle();

    expect(find.text('First payment is paid on day'), findsOneWidget);

    await tester.tap(find.text('One payment'));
    await tester.pumpAndSettle();

    expect(find.text('First payment is paid on day'), findsNothing);
  });

  testWidgets('the steppers change the pay days', (tester) async {
    await openPaySchedule(
      tester,
      settings: const DemoSettings(paymentMode: PaymentMode.twoPayments),
    );

    await tester.tap(find.byTooltip('Increase').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Decrease').last);
    await tester.pumpAndSettle();

    expect(find.text('21'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('Save keeps the schedule and goes back to the Settings', (
    tester,
  ) async {
    await openPaySchedule(tester);

    await tester.tap(find.text('Two payments'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.text('Two payments a month'), findsOneWidget);
    expect(
      tester
          .widget<SwitchListTile>(
            find.widgetWithText(SwitchListTile, 'Remind me on pay days'),
          )
          .value,
      isTrue,
    );
  });

  testWidgets('going back without Save keeps the old schedule', (tester) async {
    await openPaySchedule(tester);
    await tester.tap(find.text('Two payments'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('One payment a month'), findsOneWidget);
  });

  testWidgets('shows a skeleton while the schedule loads', (tester) async {
    final demo = await openPaySchedule(tester);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    demo.update(const DemoSettings(scenario: DemoScenario.loading));
    await tester.pump();
    await tester.tap(find.text('Pay schedule'));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(PayScheduleScreen), findsOneWidget);
    expect(find.byType(SkeletonBox), findsWidgets);
    expect(find.text('Save'), findsNothing);

    await tester.pump(const Duration(seconds: 20));
    await tester.pumpAndSettle();
  });

  testWidgets('offers Try again when the schedule cannot be loaded', (
    tester,
  ) async {
    final demo = await openPaySchedule(
      tester,
      settings: const DemoSettings(scenario: DemoScenario.noConnection),
    );

    expect(find.text('No connection'), findsOneWidget);
    expect(find.text('Save'), findsNothing);

    demo.update(const DemoSettings());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets('keeps the form when saving fails, and Try again saves', (
    tester,
  ) async {
    final demo = await openPaySchedule(tester);
    await tester.tap(find.text('Two payments'));
    await tester.pumpAndSettle();
    demo.update(const DemoSettings(scenario: DemoScenario.noConnection));

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('No connection'), findsOneWidget);

    demo.update(const DemoSettings());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.text('Two payments a month'), findsOneWidget);
  });

  testWidgets('is in Arabic', (tester) async {
    await openPaySchedule(tester, language: AppLanguage.arabic);

    expect(find.widgetWithText(AppBar, 'جدول الدفع'), findsOneWidget);
    expect(find.text('حفظ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
