import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';
import 'package:money_scribe/features/salary/bloc/fixed_items_bloc.dart';
import 'package:money_scribe/features/salary/data/fake/fake_fixed_items_repository.dart';
import 'package:money_scribe/features/salary/data/fake/fake_salary_repository.dart';
import 'package:money_scribe/features/salary/domain/fixed_item.dart';
import 'package:money_scribe/features/salary/domain/fixed_items_copy_refusal.dart';

Money rub(int rubles) => Money(rubles * 100, Currency.rub);

const october = YearMonth(2026, 10);
const march = YearMonth(2026, 3);
const august = YearMonth(2026, 8);

FixedItemDraft gym({FixedItemPart part = FixedItemPart.first}) {
  return FixedItemDraft(
    name: 'Gym',
    amount: rub(1200),
    kind: FixedItemKind.expense,
    part: part,
  );
}

void main() {
  late DemoController demo;
  late FakeFixedItemsRepository fixedItems;
  late FakeSalaryRepository salary;

  setUp(() {
    demo = DemoController(latency: Duration.zero);
    salary = FakeSalaryRepository(demo: demo);
    fixedItems = FakeFixedItemsRepository(demo: demo, salary: salary);
  });

  FixedItemsBloc build({YearMonth month = october}) {
    return FixedItemsBloc(fixedItems: fixedItems, salary: salary, month: month);
  }

  /// Starts the Bloc and waits until the items are shown.
  Future<void> start(FixedItemsBloc bloc) async {
    bloc.add(const FixedItemsStarted());
    await bloc.stream.firstWhere((s) => s.status == FixedItemsStatus.ready);
  }

  List<String> names(FixedItemsBloc bloc) =>
      bloc.state.items.map((item) => item.name).toList();

  test('starts loading the month it was given', () {
    final bloc = build();
    addTearDown(bloc.close);

    expect(bloc.state.status, FixedItemsStatus.loading);
    expect(bloc.state.month, october);
  });

  group('FixedItemsStarted', () {
    blocTest<FixedItemsBloc, FixedItemsState>(
      'loads the items and the salary of the month',
      build: build,
      act: (bloc) => bloc.add(const FixedItemsStarted()),
      expect: () => [
        isA<FixedItemsState>().having(
          (s) => s.status,
          'status',
          FixedItemsStatus.loading,
        ),
        isA<FixedItemsState>()
            .having((s) => s.status, 'status', FixedItemsStatus.ready)
            .having((s) => s.monthSaved, 'monthSaved', isTrue)
            .having((s) => s.items.length, 'items', 3)
            .having((s) => s.twoPayments, 'twoPayments', isFalse)
            .having((s) => s.salary?.totalAfterTax, 'salary', rub(104400)),
      ],
    );

    blocTest<FixedItemsBloc, FixedItemsState>(
      'knows when the month is paid in two payments',
      setUp: () =>
          demo.update(const DemoSettings(paymentMode: PaymentMode.twoPayments)),
      build: build,
      act: (bloc) => bloc.add(const FixedItemsStarted()),
      verify: (bloc) {
        expect(bloc.state.twoPayments, isTrue);
        expect(bloc.state.salary?.payments, [rub(43500), rub(60900)]);
      },
    );

    blocTest<FixedItemsBloc, FixedItemsState>(
      'a month with no saved salary has no pay and follows the default mode',
      setUp: () =>
          demo.update(const DemoSettings(paymentMode: PaymentMode.twoPayments)),
      build: () => build(month: march),
      act: (bloc) => bloc.add(const FixedItemsStarted()),
      verify: (bloc) {
        expect(bloc.state.status, FixedItemsStatus.ready);
        expect(bloc.state.monthSaved, isFalse);
        expect(bloc.state.items, isEmpty);
        expect(bloc.state.salary, isNull);
        expect(bloc.state.twoPayments, isTrue);
        expect(bloc.state.summary.pay, rub(0));
      },
    );

    blocTest<FixedItemsBloc, FixedItemsState>(
      'an account with no saved month has no month to hold items',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.empty)),
      build: build,
      act: (bloc) => bloc.add(const FixedItemsStarted()),
      verify: (bloc) {
        expect(bloc.state.status, FixedItemsStatus.ready);
        expect(bloc.state.monthSaved, isFalse);
        expect(bloc.state.items, isEmpty);
      },
    );

    blocTest<FixedItemsBloc, FixedItemsState>(
      'shows no items for a month that is not saved, whatever the server holds',
      setUp: () async {
        // Items that are left over for a month whose salary is gone.
        await fixedItems.add(march, gym());
      },
      build: () => build(month: march),
      act: (bloc) => bloc.add(const FixedItemsStarted()),
      verify: (bloc) {
        expect(bloc.state.monthSaved, isFalse);
        expect(bloc.state.items, isEmpty);
      },
    );

    blocTest<FixedItemsBloc, FixedItemsState>(
      'does not add an item to a month that is not saved',
      build: () => build(month: march),
      act: (bloc) async {
        bloc.add(const FixedItemsStarted());
        await bloc.stream.firstWhere((s) => s.status == FixedItemsStatus.ready);
        bloc.add(FixedItemAdded(gym()));
      },
      verify: (bloc) async {
        expect(bloc.state.items, isEmpty);
        expect(bloc.state.failedAction, isNull);
        expect(await fixedItems.items(march), isEmpty);
      },
    );

    blocTest<FixedItemsBloc, FixedItemsState>(
      'reports no connection',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.noConnection)),
      build: build,
      act: (bloc) => bloc.add(const FixedItemsStarted()),
      verify: (bloc) =>
          expect(bloc.state.status, FixedItemsStatus.noConnection),
    );

    blocTest<FixedItemsBloc, FixedItemsState>(
      'reports a server failure and the error',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.error)),
      build: build,
      act: (bloc) => bloc.add(const FixedItemsStarted()),
      verify: (bloc) => expect(bloc.state.status, FixedItemsStatus.failure),
      errors: () => [isA<ServerException>()],
    );
  });

  group('FixedItemsRetried', () {
    blocTest<FixedItemsBloc, FixedItemsState>(
      'loads again once the server answers',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.noConnection)),
      build: build,
      act: (bloc) async {
        bloc.add(const FixedItemsStarted());
        await bloc.stream.firstWhere(
          (s) => s.status == FixedItemsStatus.noConnection,
        );
        demo.update(const DemoSettings());
        bloc.add(const FixedItemsRetried());
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.status, FixedItemsStatus.ready);
        expect(bloc.state.items, hasLength(3));
      },
    );
  });

  group('FixedItemsPartSelected', () {
    blocTest<FixedItemsBloc, FixedItemsState>(
      'shows the items of the part that was chosen',
      setUp: () =>
          demo.update(const DemoSettings(paymentMode: PaymentMode.twoPayments)),
      build: build,
      act: (bloc) async {
        await start(bloc);
        expect(bloc.state.shownItems.map((item) => item.name), [
          'Rent',
          'Services',
        ]);
        bloc.add(const FixedItemsPartSelected(FixedItemPart.second));
      },
      verify: (bloc) {
        expect(bloc.state.part, FixedItemPart.second);
        expect(bloc.state.shownItems.map((item) => item.name), ['Scholarship']);
        expect(bloc.state.summary.balance, rub(65900));
      },
    );

    blocTest<FixedItemsBloc, FixedItemsState>(
      'with one payment every item is shown whatever the part',
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc.add(const FixedItemsPartSelected(FixedItemPart.second));
      },
      verify: (bloc) => expect(bloc.state.shownItems, hasLength(3)),
    );
  });

  group('FixedItemAdded', () {
    blocTest<FixedItemsBloc, FixedItemsState>(
      'adds the item to the end and counts it in the balance',
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc.add(FixedItemAdded(gym()));
      },
      verify: (bloc) {
        expect(names(bloc), ['Scholarship', 'Rent', 'Services', 'Gym']);
        expect(bloc.state.summary.balance, rub(73700));
        expect(bloc.state.failedAction, isNull);
      },
    );

    blocTest<FixedItemsBloc, FixedItemsState>(
      'keeps the list and remembers the action when saving fails',
      build: build,
      act: (bloc) async {
        await start(bloc);
        demo.update(const DemoSettings(save: DemoSave.fails));
        bloc.add(FixedItemAdded(gym()));
      },
      verify: (bloc) {
        expect(names(bloc), ['Scholarship', 'Rent', 'Services']);
        expect(bloc.state.failedAction, FixedItemAdded(gym()));
      },
    );

    blocTest<FixedItemsBloc, FixedItemsState>(
      'trying again once the server accepts it adds the item',
      build: build,
      act: (bloc) async {
        await start(bloc);
        demo.update(const DemoSettings(save: DemoSave.fails));
        bloc.add(FixedItemAdded(gym()));
        await bloc.stream.firstWhere((s) => s.failedAction != null);
        demo.update(const DemoSettings());
        bloc.add(bloc.state.failedAction!);
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(names(bloc), contains('Gym'));
        expect(bloc.state.failedAction, isNull);
      },
    );
  });

  group('an item changed on another device', () {
    blocTest<FixedItemsBloc, FixedItemsState>(
      'is not changed, the list is loaded again and the change is offered',
      build: build,
      act: (bloc) async {
        await start(bloc);
        final rent = bloc.state.items[1];
        // Another device changes the rent first.
        await fixedItems.update(october, rent.id, gym(), version: rent.version);
        bloc.add(FixedItemChanged(rent.id, gym(part: FixedItemPart.second)));
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.status, FixedItemsStatus.ready);
        expect(bloc.state.items[1].version, 2);
        expect(bloc.state.items[1].part, FixedItemPart.first);
        expect(bloc.state.staleAction, isA<FixedItemChanged>());
        expect(bloc.state.failedAction, isNull);
      },
    );

    blocTest<FixedItemsBloc, FixedItemsState>(
      'applied again, it goes through on the latest version',
      build: build,
      act: (bloc) async {
        await start(bloc);
        final rent = bloc.state.items[1];
        await fixedItems.update(october, rent.id, gym(), version: rent.version);
        bloc.add(FixedItemChanged(rent.id, gym(part: FixedItemPart.second)));
        await bloc.stream.firstWhere((s) => s.staleAction != null);
        bloc.add(bloc.state.staleAction!);
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.items[1].part, FixedItemPart.second);
        expect(bloc.state.items[1].version, 3);
        expect(bloc.state.staleAction, isNull);
      },
    );

    blocTest<FixedItemsBloc, FixedItemsState>(
      'deleted on another device, a change is stale and the item stays gone',
      build: build,
      act: (bloc) async {
        await start(bloc);
        final rent = bloc.state.items[1];
        await fixedItems.delete(october, rent.id, version: rent.version);
        bloc.add(FixedItemChanged(rent.id, gym()));
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.items, hasLength(2));
        expect(bloc.state.staleAction, isA<FixedItemChanged>());
      },
    );

    blocTest<FixedItemsBloc, FixedItemsState>(
      'is not deleted, and stays on the list at its latest version',
      build: build,
      act: (bloc) async {
        await start(bloc);
        final rent = bloc.state.items[1];
        await fixedItems.update(october, rent.id, gym(), version: rent.version);
        bloc.add(FixedItemDeleted(rent.id));
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.items, hasLength(3));
        expect(bloc.state.staleAction, isA<FixedItemDeleted>());
      },
    );
  });

  group('FixedItemChanged', () {
    blocTest<FixedItemsBloc, FixedItemsState>(
      'replaces the item and counts the new amount',
      build: build,
      act: (bloc) async {
        await start(bloc);
        final rent = bloc.state.items[1];
        bloc.add(FixedItemChanged(rent.id, gym()));
      },
      verify: (bloc) {
        expect(names(bloc), ['Scholarship', 'Gym', 'Services']);
        expect(bloc.state.summary.balance, rub(104400 + 5000 - 1200 - 4500));
      },
    );

    blocTest<FixedItemsBloc, FixedItemsState>(
      'moving an item to the other part moves it between the lists',
      setUp: () =>
          demo.update(const DemoSettings(paymentMode: PaymentMode.twoPayments)),
      build: build,
      act: (bloc) async {
        await start(bloc);
        final rent = bloc.state.items[1];
        bloc.add(
          FixedItemChanged(
            rent.id,
            FixedItemDraft(
              name: rent.name,
              amount: rent.amount,
              kind: rent.kind,
              part: FixedItemPart.second,
            ),
          ),
        );
      },
      verify: (bloc) {
        expect(bloc.state.shownItems.map((item) => item.name), ['Services']);
      },
    );

    blocTest<FixedItemsBloc, FixedItemsState>(
      'keeps the item when saving fails',
      build: build,
      act: (bloc) async {
        await start(bloc);
        demo.update(const DemoSettings(save: DemoSave.fails));
        bloc.add(FixedItemChanged(bloc.state.items[1].id, gym()));
      },
      verify: (bloc) {
        expect(names(bloc), ['Scholarship', 'Rent', 'Services']);
        expect(bloc.state.failedAction, isA<FixedItemChanged>());
      },
    );
  });

  group('FixedItemDeleted', () {
    blocTest<FixedItemsBloc, FixedItemsState>(
      'removes the item and its amount from the balance',
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc.add(FixedItemDeleted(bloc.state.items[1].id));
      },
      verify: (bloc) {
        expect(names(bloc), ['Scholarship', 'Services']);
        expect(bloc.state.summary.balance, rub(104400 + 5000 - 4500));
      },
    );

    blocTest<FixedItemsBloc, FixedItemsState>(
      'deleting every item leaves the month empty',
      build: build,
      act: (bloc) async {
        await start(bloc);
        for (final item in List.of(bloc.state.items)) {
          bloc.add(FixedItemDeleted(item.id));
        }
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.items, isEmpty);
        expect(bloc.state.summary.balance, rub(104400));
      },
    );

    blocTest<FixedItemsBloc, FixedItemsState>(
      'keeps the item when deleting fails',
      build: build,
      act: (bloc) async {
        await start(bloc);
        demo.update(const DemoSettings(save: DemoSave.fails));
        bloc.add(FixedItemDeleted(bloc.state.items[1].id));
      },
      verify: (bloc) {
        expect(bloc.state.items, hasLength(3));
        expect(bloc.state.failedAction, isA<FixedItemDeleted>());
      },
    );

    blocTest<FixedItemsBloc, FixedItemsState>(
      'the next action clears the failure',
      build: build,
      act: (bloc) async {
        await start(bloc);
        demo.update(const DemoSettings(save: DemoSave.fails));
        bloc.add(FixedItemDeleted(bloc.state.items[1].id));
        await bloc.stream.firstWhere((s) => s.failedAction != null);
        demo.update(const DemoSettings());
        bloc.add(FixedItemAdded(gym()));
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) => expect(bloc.state.failedAction, isNull),
    );
  });

  group('FixedItemsCopied', () {
    Future<void> copied(FixedItemsBloc bloc) {
      return bloc.stream.firstWhere((s) => !s.copying);
    }

    blocTest<FixedItemsBloc, FixedItemsState>(
      'adds the items of the month before to the ones the month has',
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc.add(const FixedItemsCopied());
        await bloc.stream.firstWhere((s) => s.items.length == 6);
      },
      verify: (bloc) {
        expect(names(bloc), [
          'Scholarship',
          'Rent',
          'Services',
          'Scholarship',
          'Rent',
          'Services',
        ]);
        expect(bloc.state.failedAction, isNull);
        expect(bloc.state.copyRefusal, isNull);
      },
    );

    test('says it is copying until the server has answered', () async {
      final bloc = build();
      addTearDown(bloc.close);
      await start(bloc);
      final copying = <bool>[];
      final listening = bloc.stream.listen((s) => copying.add(s.copying));

      bloc.add(const FixedItemsCopied());
      await copied(bloc);
      await Future<void>.delayed(Duration.zero);
      await listening.cancel();

      expect(copying.first, isTrue);
      expect(copying.last, isFalse);
      expect(bloc.state.copying, isFalse);
    });

    test('a second press while one copy runs is dropped', () async {
      final bloc = build();
      addTearDown(bloc.close);
      await start(bloc);

      bloc
        ..add(const FixedItemsCopied())
        ..add(const FixedItemsCopied());
      await copied(bloc);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(bloc.state.items, hasLength(6));
    });

    blocTest<FixedItemsBloc, FixedItemsState>(
      'the oldest saved month is told it has nothing to copy from',
      build: () => build(month: august),
      act: (bloc) async {
        await start(bloc);
        bloc.add(const FixedItemsCopied());
        await bloc.stream.firstWhere((s) => s.copyRefusal != null);
      },
      verify: (bloc) {
        expect(bloc.state.copyRefusal, FixedItemsCopyRefusal.noEarlierMonth);
        expect(bloc.state.items, hasLength(3));
        // A refusal is not a failure: asking again changes nothing.
        expect(bloc.state.failedAction, isNull);
        expect(bloc.state.copying, isFalse);
      },
    );

    blocTest<FixedItemsBloc, FixedItemsState>(
      'the next action clears the refusal',
      build: () => build(month: august),
      act: (bloc) async {
        await start(bloc);
        bloc.add(const FixedItemsCopied());
        await bloc.stream.firstWhere((s) => s.copyRefusal != null);
        bloc.add(FixedItemAdded(gym()));
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.copyRefusal, isNull);
        expect(bloc.state.items, hasLength(4));
      },
    );

    blocTest<FixedItemsBloc, FixedItemsState>(
      'a copy the server does not accept keeps the list and can be retried',
      build: build,
      act: (bloc) async {
        await start(bloc);
        demo.update(const DemoSettings(save: DemoSave.fails));
        bloc.add(const FixedItemsCopied());
        await bloc.stream.firstWhere((s) => s.failedAction != null);
        demo.update(const DemoSettings());
        bloc.add(bloc.state.failedAction!);
        await bloc.stream.firstWhere((s) => s.items.length == 6);
      },
      verify: (bloc) {
        expect(bloc.state.failedAction, isNull);
        expect(bloc.state.copying, isFalse);
      },
    );

    blocTest<FixedItemsBloc, FixedItemsState>(
      'the failure of a copy keeps the items as they were',
      build: build,
      act: (bloc) async {
        await start(bloc);
        demo.update(const DemoSettings(save: DemoSave.fails));
        bloc.add(const FixedItemsCopied());
        await bloc.stream.firstWhere((s) => s.failedAction != null);
      },
      verify: (bloc) {
        expect(bloc.state.items, hasLength(3));
        expect(bloc.state.failedAction, isA<FixedItemsCopied>());
      },
    );

    blocTest<FixedItemsBloc, FixedItemsState>(
      'does nothing for a month that is not saved',
      build: () => build(month: march),
      act: (bloc) async {
        await start(bloc);
        bloc.add(const FixedItemsCopied());
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.items, isEmpty);
        expect(bloc.state.copyRefusal, isNull);
        expect(bloc.state.copying, isFalse);
      },
    );
  });

  group('the demo panel', () {
    blocTest<FixedItemsBloc, FixedItemsState>(
      'switching to two payments loads again and gives the items parts',
      build: build,
      act: (bloc) async {
        await start(bloc);
        expect(bloc.state.twoPayments, isFalse);
        demo.update(
          demo.settings.copyWith(paymentMode: PaymentMode.twoPayments),
        );
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.status, FixedItemsStatus.ready);
        expect(bloc.state.twoPayments, isTrue);
      },
    );

    blocTest<FixedItemsBloc, FixedItemsState>(
      'switching to an error fails',
      build: build,
      act: (bloc) async {
        await start(bloc);
        demo.update(demo.settings.copyWith(scenario: DemoScenario.error));
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) => expect(bloc.state.status, FixedItemsStatus.failure),
      // The fixed items and the salary both announce the change, so the
      // screen loads, and fails, twice.
      errors: () => [isA<ServerException>(), isA<ServerException>()],
    );
  });
}
