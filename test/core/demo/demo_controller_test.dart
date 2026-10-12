import 'package:flutter_test/flutter_test.dart';
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
}
