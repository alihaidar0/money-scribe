import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/features/overview/bloc/debt_choice_bloc.dart';
import 'package:money_scribe/features/overview/data/fake/fake_overview_repository.dart';
import 'package:money_scribe/features/overview/data/fake/overview_seed.dart';

void main() {
  late DemoController demo;

  setUp(() => demo = DemoController(latency: Duration.zero));

  DebtChoiceBloc build() {
    return DebtChoiceBloc(repository: FakeOverviewRepository(demo: demo));
  }

  blocTest<DebtChoiceBloc, DebtChoiceState>(
    'offers the debts that can be repaid',
    build: build,
    act: (bloc) => bloc.add(const DebtChoiceStarted()),
    expect: () => [
      const DebtChoiceState(),
      DebtChoiceState(
        status: DebtChoiceStatus.ready,
        debts: OverviewSeed.debtsToRepay(),
      ),
    ],
  );

  blocTest<DebtChoiceBloc, DebtChoiceState>(
    'offers none for an account with no data',
    setUp: () => demo.update(const DemoSettings(scenario: DemoScenario.empty)),
    build: build,
    act: (bloc) => bloc.add(const DebtChoiceStarted()),
    expect: () => const [
      DebtChoiceState(),
      DebtChoiceState(status: DebtChoiceStatus.ready),
    ],
  );

  blocTest<DebtChoiceBloc, DebtChoiceState>(
    'reports no connection',
    setUp: () =>
        demo.update(const DemoSettings(scenario: DemoScenario.noConnection)),
    build: build,
    act: (bloc) => bloc.add(const DebtChoiceStarted()),
    expect: () => const [
      DebtChoiceState(),
      DebtChoiceState(status: DebtChoiceStatus.noConnection),
    ],
  );

  blocTest<DebtChoiceBloc, DebtChoiceState>(
    'reports a server failure and the error',
    setUp: () => demo.update(const DemoSettings(scenario: DemoScenario.error)),
    build: build,
    act: (bloc) => bloc.add(const DebtChoiceStarted()),
    expect: () => const [
      DebtChoiceState(),
      DebtChoiceState(status: DebtChoiceStatus.failure),
    ],
    errors: () => [isA<ServerException>()],
  );

  blocTest<DebtChoiceBloc, DebtChoiceState>(
    'Try again loads once more',
    setUp: () =>
        demo.update(const DemoSettings(scenario: DemoScenario.noConnection)),
    build: build,
    act: (bloc) async {
      bloc.add(const DebtChoiceStarted());
      await pumpEventQueue();
      demo.update(const DemoSettings());
      bloc.add(const DebtChoiceStarted());
    },
    verify: (bloc) => expect(bloc.state.status, DebtChoiceStatus.ready),
  );
}
