import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/features/salary/data/fake/fake_fixed_items_repository.dart';
import 'package:money_scribe/features/salary/data/fake/fake_salary_repository.dart';
import 'package:money_scribe/features/salary/domain/fixed_item.dart';
import 'package:money_scribe/features/salary/domain/fixed_items_copy_refusal.dart';
import 'package:money_scribe/features/salary/domain/salary_inputs.dart';
import 'package:money_scribe/features/salary/domain/salary_month.dart';

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
  late FakeSalaryRepository salary;
  late FakeFixedItemsRepository repository;

  setUp(() {
    demo = DemoController(latency: Duration.zero);
    salary = FakeSalaryRepository(demo: demo);
    repository = FakeFixedItemsRepository(demo: demo, salary: salary);
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
        version: rent.version,
      );

      expect(saved.id, rent.id);
      expect(saved.version, rent.version + 1);
      final items = await repository.items(october);
      expect(items[1].name, 'Gym');
      expect(items[1].amount, const Money(3100000, Currency.rub));
      expect(items, hasLength(3));
    });

    test('an item that is gone is stale', () async {
      await expectLater(
        repository.update(october, 'missing', gym(), version: 1),
        throwsA(isA<StaleRecordException>()),
      );
    });

    test('an item changed since it was read is refused and kept', () async {
      final rent = (await repository.items(october))[1];
      await repository.update(october, rent.id, gym(), version: rent.version);

      await expectLater(
        repository.update(
          october,
          rent.id,
          gym(rubles: 1),
          version: rent.version,
        ),
        throwsA(isA<StaleRecordException>()),
      );
      expect(
        (await repository.items(october))[1].amount,
        const Money(120000, Currency.rub),
      );
    });
  });

  group('delete', () {
    test('removes the item', () async {
      final rent = (await repository.items(october))[1];

      await repository.delete(october, rent.id, version: rent.version);

      expect(names(await repository.items(october)), [
        'Scholarship',
        'Services',
      ]);
    });

    test('deleting what is gone does nothing', () async {
      await repository.delete(october, 'missing', version: 1);

      expect(await repository.items(october), hasLength(3));
    });

    test('an item changed since it was read is refused and kept', () async {
      final rent = (await repository.items(october))[1];
      await repository.update(october, rent.id, gym(), version: rent.version);

      await expectLater(
        repository.delete(october, rent.id, version: rent.version),
        throwsA(isA<StaleRecordException>()),
      );
      expect(await repository.items(october), hasLength(3));
    });

    test('a month emptied by deleting stays empty', () async {
      for (final item in await repository.items(october)) {
        await repository.delete(october, item.id, version: item.version);
      }

      expect(await repository.items(october), isEmpty);
    });
  });

  group('copyFromPrevious', () {
    const august = YearMonth(2026, 8);

    Matcher refusedWith(FixedItemsCopyRefusal refusal) {
      return throwsA(
        isA<FixedItemsCopyRefusedException>().having(
          (e) => e.refusal,
          'refusal',
          refusal,
        ),
      );
    }

    test('adds the items of the month before to those the month has', () async {
      final items = await repository.copyFromPrevious(september);

      expect(names(items), [
        'Scholarship',
        'Rent',
        'Services',
        'Scholarship',
        'Rent',
        'Services',
      ]);
      expect(await repository.items(september), items);
    });

    test('copies what each item is made of under new ids', () async {
      final source = await repository.items(august);
      final items = await repository.copyFromPrevious(september);

      final copies = items.sublist(3);
      expect(
        [for (final item in copies) item.draft],
        [for (final item in source) item.draft],
      );
      expect({for (final item in items) item.id}, hasLength(6));
      expect(copies.map((item) => item.version), everyElement(1));
      // The source month keeps its own items.
      expect(await repository.items(august), source);
    });

    test('copies from the most recent month before it', () async {
      // October is copied from September, not from August.
      final rent = (await repository.items(september))[1];
      await repository.delete(september, rent.id, version: rent.version);

      final items = await repository.copyFromPrevious(october);

      expect(names(items), [
        'Scholarship',
        'Rent',
        'Services',
        'Scholarship',
        'Services',
      ]);
    });

    test('the oldest saved month has none to copy from', () async {
      await expectLater(
        repository.copyFromPrevious(august),
        refusedWith(FixedItemsCopyRefusal.noEarlierMonth),
      );
      expect(await repository.items(august), hasLength(3));
    });

    test('a month that is not saved cannot be copied into', () async {
      await expectLater(
        repository.copyFromPrevious(march),
        refusedWith(FixedItemsCopyRefusal.noEarlierMonth),
      );
      expect(await repository.items(march), isEmpty);
    });

    test('an account with no saved month has nothing to copy from', () async {
      demo.update(const DemoSettings(scenario: DemoScenario.empty));

      await expectLater(
        repository.copyFromPrevious(october),
        refusedWith(FixedItemsCopyRefusal.noEarlierMonth),
      );
    });

    test('a month in another currency is refused, copying nothing', () async {
      await salary.save(
        SalaryMonth(
          month: const YearMonth(2026, 11),
          inputs: SalaryInputs(
            baseSalary: const Money(10000000, Currency.usd),
            foodPerDay: const Money(50000, Currency.usd),
            workingDaysInMonth: 20,
            workingHoursInMonth: 160,
            extraHoursHundredths: 0,
            taxRateBasisPoints: 1300,
          ),
          firstPayDay: 20,
          secondPayDay: 5,
        ),
      );

      await expectLater(
        repository.copyFromPrevious(const YearMonth(2026, 11)),
        refusedWith(FixedItemsCopyRefusal.currencyMismatch),
      );
      expect(await repository.items(const YearMonth(2026, 11)), isEmpty);
    });

    test(
      'a month that would pass the limit is refused, copying nothing',
      () async {
        for (var i = 0; i < 98; i++) {
          await repository.add(september, gym());
        }

        // 3 seeded, 98 added and 3 to copy: 104 items.
        await expectLater(
          repository.copyFromPrevious(september),
          refusedWith(FixedItemsCopyRefusal.limitReached),
        );
        expect(await repository.items(september), hasLength(101));
      },
    );

    test('reports no connection and a server failure', () async {
      demo.update(const DemoSettings(scenario: DemoScenario.noConnection));
      await expectLater(
        repository.copyFromPrevious(september),
        throwsA(isA<NoConnectionException>()),
      );

      demo.update(const DemoSettings(scenario: DemoScenario.error));
      await expectLater(
        repository.copyFromPrevious(september),
        throwsA(isA<ServerException>()),
      );
    });

    test('a save that fails copies nothing', () async {
      demo.update(const DemoSettings(save: DemoSave.fails));

      await expectLater(
        repository.copyFromPrevious(september),
        throwsA(isA<NoConnectionException>()),
      );
      demo.update(const DemoSettings());
      expect(await repository.items(september), hasLength(3));
    });
  });

  test('tells the screens when the demo panel changes the data', () async {
    final changed = expectLater(repository.changes, emits(null));

    demo.update(const DemoSettings(scenario: DemoScenario.empty));

    await changed;
  });
}
