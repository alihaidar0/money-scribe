import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';

void main() {
  group('simulateRequest', () {
    test('answers in the normal scenario', () async {
      final demo = DemoController(latency: Duration.zero);

      await expectLater(demo.simulateRequest(), completes);
    });

    test('fails with no connection', () async {
      final demo = DemoController(
        initial: const DemoSettings(scenario: DemoScenario.noConnection),
        latency: Duration.zero,
      );

      await expectLater(
        demo.simulateRequest(),
        throwsA(isA<NoConnectionException>()),
      );
    });

    test('fails with a server error', () async {
      final demo = DemoController(
        initial: const DemoSettings(scenario: DemoScenario.error),
        latency: Duration.zero,
      );

      await expectLater(
        demo.simulateRequest(),
        throwsA(isA<ServerException>()),
      );
    });

    test('empty answers like normal: emptiness is up to the data', () async {
      final demo = DemoController(
        initial: const DemoSettings(scenario: DemoScenario.empty),
        latency: Duration.zero,
      );

      await expectLater(demo.simulateRequest(), completes);
    });
  });

  group('update', () {
    test('tells the listeners about a change', () async {
      final demo = DemoController(latency: Duration.zero);
      final changes = <DemoSettings>[];
      final subscription = demo.changes.listen(changes.add);
      addTearDown(subscription.cancel);

      demo.update(const DemoSettings(code: DemoCode.expired));
      await Future<void>.delayed(Duration.zero);

      expect(demo.settings.code, DemoCode.expired);
      expect(changes, [const DemoSettings(code: DemoCode.expired)]);
    });

    test('says nothing when nothing changed', () async {
      final demo = DemoController(latency: Duration.zero);
      final changes = <DemoSettings>[];
      final subscription = demo.changes.listen(changes.add);
      addTearDown(subscription.cancel);

      demo.update(const DemoSettings());
      await Future<void>.delayed(Duration.zero);

      expect(changes, isEmpty);
    });
  });

  group('simulateSave', () {
    test('saves in the normal scenario', () async {
      final demo = DemoController(latency: Duration.zero);

      await expectLater(demo.simulateSave(), completes);
    });

    test('fails when the panel says the next save does', () async {
      final demo = DemoController(
        initial: const DemoSettings(save: DemoSave.fails),
        latency: Duration.zero,
      );

      await expectLater(
        demo.simulateSave(),
        throwsA(isA<NoConnectionException>()),
      );
    });

    test('fails like any request when the server is down', () async {
      final demo = DemoController(
        initial: const DemoSettings(scenario: DemoScenario.error),
        latency: Duration.zero,
      );

      await expectLater(demo.simulateSave(), throwsA(isA<ServerException>()));
    });

    test('a request that is not a save ignores the save switch', () async {
      final demo = DemoController(
        initial: const DemoSettings(save: DemoSave.fails),
        latency: Duration.zero,
      );

      await expectLater(demo.simulateRequest(), completes);
    });
  });

  group('dataChanges', () {
    test('emits when the scenario or the payment mode changes', () async {
      final demo = DemoController(latency: Duration.zero);
      var count = 0;
      final subscription = demo.dataChanges.listen((_) => count++);
      addTearDown(subscription.cancel);

      demo
        ..update(const DemoSettings(scenario: DemoScenario.error))
        ..update(
          const DemoSettings(
            scenario: DemoScenario.error,
            paymentMode: PaymentMode.twoPayments,
          ),
        );
      await Future<void>.delayed(Duration.zero);

      expect(count, 2);
    });

    test('stays quiet for the other switches', () async {
      final demo = DemoController(latency: Duration.zero);
      var count = 0;
      final subscription = demo.dataChanges.listen((_) => count++);
      addTearDown(subscription.cancel);

      demo
        ..update(const DemoSettings(save: DemoSave.fails))
        ..update(const DemoSettings(signIn: DemoSignIn.locked));
      await Future<void>.delayed(Duration.zero);

      expect(count, 0);
    });

    test('compares with the settings at the time of listening', () async {
      final demo = DemoController(
        initial: const DemoSettings(scenario: DemoScenario.error),
        latency: Duration.zero,
      );
      var count = 0;
      final subscription = demo.dataChanges.listen((_) => count++);
      addTearDown(subscription.cancel);

      demo.update(
        const DemoSettings(scenario: DemoScenario.error, save: DemoSave.fails),
      );
      await Future<void>.delayed(Duration.zero);

      expect(count, 0);
    });
  });

  group('the schedule of a saved month', () {
    const october = YearMonth(2026, 10);
    const september = YearMonth(2026, 9);

    test('is the account schedule until the month is saved', () {
      final demo = DemoController(
        initial: const DemoSettings(paymentMode: PaymentMode.twoPayments),
        latency: Duration.zero,
      );

      expect(demo.paymentModeOf(october), PaymentMode.twoPayments);
    });

    test('a saved month keeps its own schedule', () {
      final demo = DemoController(latency: Duration.zero)
        ..setMonthPaymentMode(september, PaymentMode.twoPayments);

      expect(demo.paymentModeOf(september), PaymentMode.twoPayments);
      expect(demo.paymentModeOf(october), PaymentMode.onePayment);

      demo
        ..update(const DemoSettings(paymentMode: PaymentMode.twoPayments))
        ..update(const DemoSettings());

      expect(demo.paymentModeOf(september), PaymentMode.twoPayments);
    });

    test('forgetting it goes back to the account schedule', () {
      final demo = DemoController(latency: Duration.zero)
        ..setMonthPaymentMode(september, PaymentMode.twoPayments)
        ..clearMonthPaymentMode(september);

      expect(demo.paymentModeOf(september), PaymentMode.onePayment);
    });

    test('dataChangesWithSchedules also tells when a month is saved', () async {
      final demo = DemoController(latency: Duration.zero);
      var count = 0;
      final subscription = demo.dataChangesWithSchedules.listen((_) => count++);
      addTearDown(subscription.cancel);

      demo
        ..setMonthPaymentMode(september, PaymentMode.twoPayments)
        // The same schedule again changes nothing.
        ..setMonthPaymentMode(september, PaymentMode.twoPayments)
        ..update(const DemoSettings(paymentMode: PaymentMode.twoPayments))
        ..clearMonthPaymentMode(september);
      await Future<void>.delayed(Duration.zero);

      expect(count, 3);
    });

    test('dataChanges alone does not tell when a month is saved', () async {
      final demo = DemoController(latency: Duration.zero);
      var count = 0;
      final subscription = demo.dataChanges.listen((_) => count++);
      addTearDown(subscription.cancel);

      demo.setMonthPaymentMode(september, PaymentMode.twoPayments);
      await Future<void>.delayed(Duration.zero);

      expect(count, 0);
    });
  });
}
