import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/features/salary/data/fake/fake_fixed_items_repository.dart';
import 'package:money_scribe/features/salary/domain/fixed_item.dart';

const october = YearMonth(2026, 10);
const september = YearMonth(2026, 9);
const march = YearMonth(2026, 3);

FixedItemDraft gym({int rubles = 1200}) {
  return FixedItemDraft(
    name: 'Gym',
    amount: Money(rubles * 100, Currency.rub),
    kind: FixedItemKind.expense,
  );
}

void main() {
  late DemoController demo;
  late FakeFixedItemsRepository repository;

  setUp(() {
    demo = DemoController(latency: Duration.zero);
    repository = FakeFixedItemsRepository(demo: demo);
  });

  List<String> names(List<FixedItem> items) =>
      items.map((item) => item.name).toList();

  group('items', () {
    test('a month with a saved salary has the seeded items', () async {
      expect(names(await repository.items(october)), [
        'Scholarship',
        'Rent',
        'Services',
      ]);
    });

    test('a month outside the seed has none', () async {
      expect(await repository.items(march), isEmpty);
    });

    test('an account with no data has none', () async {
      demo.update(const DemoSettings(scenario: DemoScenario.empty));

      expect(await repository.items(october), isEmpty);
    });

    test('reports no connection and a server failure', () async {
      demo.update(const DemoSettings(scenario: DemoScenario.noConnection));
      await expectLater(
        repository.items(october),
        throwsA(isA<NoConnectionException>()),
      );

      demo.update(const DemoSettings(scenario: DemoScenario.error));
      await expectLater(
        repository.items(october),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('add', () {
    test('keeps the item, with an id of its own, after the others', () async {
      final first = await repository.add(october, gym());
      final second = await repository.add(october, gym(rubles: 300));

      expect(first.id, isNot(second.id));
      expect(names(await repository.items(october)), [
        'Scholarship',
        'Rent',
        'Services',
        'Gym',
        'Gym',
      ]);
    });

    test('belongs to its month only', () async {
      await repository.add(march, gym());

      expect(names(await repository.items(march)), ['Gym']);
      expect(await repository.items(september), hasLength(3));
    });

    test('fails when the next save is set to fail', () async {
      demo.update(const DemoSettings(save: DemoSave.fails));

      await expectLater(
        repository.add(october, gym()),
        throwsA(isA<NoConnectionException>()),
      );
      expect(await repository.items(october), hasLength(3));
    });
  });

  group('update', () {
    test('replaces what the item is made of, in place', () async {
      final rent = (await repository.items(october))[1];

      final saved = await repository.update(
        october,
        rent.id,
        gym(rubles: 31000),
      );

      expect(saved.id, rent.id);
      final items = await repository.items(october);
      expect(items[1].name, 'Gym');
      expect(items[1].amount, const Money(3100000, Currency.rub));
      expect(items, hasLength(3));
    });

    test('an item that is gone is a server failure', () async {
      await expectLater(
        repository.update(october, 'missing', gym()),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('delete', () {
    test('removes the item', () async {
      final rent = (await repository.items(october))[1];

      await repository.delete(october, rent.id);

      expect(names(await repository.items(october)), [
        'Scholarship',
        'Services',
      ]);
    });

    test('deleting what is gone does nothing', () async {
      await repository.delete(october, 'missing');

      expect(await repository.items(october), hasLength(3));
    });

    test('a month emptied by deleting stays empty', () async {
      for (final item in await repository.items(october)) {
        await repository.delete(october, item.id);
      }

      expect(await repository.items(october), isEmpty);
    });
  });

  test('tells the screens when the demo panel changes the data', () async {
    final changed = expectLater(repository.changes, emits(null));

    demo.update(const DemoSettings(scenario: DemoScenario.empty));

    await changed;
  });
}
