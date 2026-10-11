import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/errors/data_exception.dart';

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
}
