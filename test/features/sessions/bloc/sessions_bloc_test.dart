import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/features/sessions/bloc/sessions_bloc.dart';
import 'package:money_scribe/features/sessions/data/fake/fake_sessions_repository.dart';

void main() {
  late DemoController demo;
  late FakeSessionsRepository repository;

  setUp(() {
    demo = DemoController(latency: Duration.zero);
    repository = FakeSessionsRepository(demo: demo);
  });

  SessionsBloc build() => SessionsBloc(repository: repository);

  Future<void> start(SessionsBloc bloc) async {
    bloc.add(const SessionsStarted());
    await bloc.stream.firstWhere((s) => s.status == SessionsStatus.ready);
  }

  test('starts loading the active tab', () {
    final bloc = build();
    addTearDown(bloc.close);

    expect(bloc.state.status, SessionsStatus.loading);
    expect(bloc.state.tab, SessionsTab.active);
    expect(bloc.state.previousStatus, PreviousStatus.idle);
  });

  group('SessionsStarted', () {
    blocTest<SessionsBloc, SessionsState>(
      'loads the active sessions, and not the ended ones yet',
      build: build,
      act: (bloc) => bloc.add(const SessionsStarted()),
      verify: (bloc) {
        expect(bloc.state.status, SessionsStatus.ready);
        expect(bloc.state.active, hasLength(2));
        expect(bloc.state.others.map((s) => s.id), ['session-chrome']);
        expect(bloc.state.previousStatus, PreviousStatus.idle);
        expect(bloc.state.previous, isEmpty);
      },
    );

    blocTest<SessionsBloc, SessionsState>(
      'reports no connection and loads again on Retry',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.noConnection)),
      build: build,
      act: (bloc) async {
        bloc.add(const SessionsStarted());
        await bloc.stream.firstWhere(
          (s) => s.status == SessionsStatus.noConnection,
        );
        demo.update(const DemoSettings());
        bloc.add(const SessionsRetried());
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) => expect(bloc.state.status, SessionsStatus.ready),
    );

    blocTest<SessionsBloc, SessionsState>(
      'reports a server failure and the error',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.error)),
      build: build,
      act: (bloc) => bloc.add(const SessionsStarted()),
      verify: (bloc) => expect(bloc.state.status, SessionsStatus.failure),
      errors: () => [isA<ServerException>()],
    );
  });

  group('the Previous tab', () {
    blocTest<SessionsBloc, SessionsState>(
      'is loaded the first time it is opened, grouped by device',
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc.add(const SessionsTabSelected(SessionsTab.previous));
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.tab, SessionsTab.previous);
        expect(bloc.state.previousStatus, PreviousStatus.ready);
        expect(bloc.state.previous, hasLength(3));
        expect(bloc.state.previousGroups.map((g) => g.deviceName), [
          'Chrome on Windows',
          'Pixel 8',
        ]);
        expect(bloc.state.previousGroups.first.sessions, hasLength(2));
      },
    );

    blocTest<SessionsBloc, SessionsState>(
      'is not loaded again when the tab is chosen again',
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc.add(const SessionsTabSelected(SessionsTab.previous));
        await bloc.stream.firstWhere(
          (s) => s.previousStatus == PreviousStatus.ready,
        );
        // Another device ends a session; the tab does not pick it up by itself.
        await repository.end('session-chrome');
        bloc
          ..add(const SessionsTabSelected(SessionsTab.active))
          ..add(const SessionsTabSelected(SessionsTab.previous));
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) => expect(bloc.state.previous, hasLength(3)),
    );

    blocTest<SessionsBloc, SessionsState>(
      'reports no connection and loads again on Retry',
      build: build,
      act: (bloc) async {
        await start(bloc);
        demo.update(const DemoSettings(scenario: DemoScenario.noConnection));
        bloc.add(const SessionsTabSelected(SessionsTab.previous));
        await bloc.stream.firstWhere(
          (s) => s.previousStatus == PreviousStatus.noConnection,
        );
        demo.update(const DemoSettings());
        bloc.add(const SessionsRetried());
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.previousStatus, PreviousStatus.ready);
        expect(bloc.state.status, SessionsStatus.ready);
      },
    );

    blocTest<SessionsBloc, SessionsState>(
      'loads the next page and adds it after the first',
      setUp: () => repository = FakeSessionsRepository(demo: demo, pageSize: 2),
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc.add(const SessionsTabSelected(SessionsTab.previous));
        await bloc.stream.firstWhere(
          (s) => s.previousStatus == PreviousStatus.ready,
        );
        bloc.add(const PreviousSessionsMoreRequested());
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.previous, hasLength(3));
        expect(bloc.state.previousNext, isNull);
        expect(bloc.state.loadingMore, isFalse);
        expect(bloc.state.loadMoreFailed, isFalse);
      },
    );

    blocTest<SessionsBloc, SessionsState>(
      'keeps what it has when the next page does not load',
      setUp: () => repository = FakeSessionsRepository(demo: demo, pageSize: 2),
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc.add(const SessionsTabSelected(SessionsTab.previous));
        await bloc.stream.firstWhere(
          (s) => s.previousStatus == PreviousStatus.ready,
        );
        demo.update(const DemoSettings(scenario: DemoScenario.noConnection));
        bloc.add(const PreviousSessionsMoreRequested());
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.previous, hasLength(2));
        expect(bloc.state.loadMoreFailed, isTrue);
        expect(bloc.state.previousNext, isNotNull);
      },
    );

    blocTest<SessionsBloc, SessionsState>(
      'asks for nothing on the last page',
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc.add(const SessionsTabSelected(SessionsTab.previous));
        await bloc.stream.firstWhere(
          (s) => s.previousStatus == PreviousStatus.ready,
        );
        bloc.add(const PreviousSessionsMoreRequested());
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) => expect(bloc.state.loadingMore, isFalse),
    );
  });

  group('SessionEndConfirmed', () {
    blocTest<SessionsBloc, SessionsState>(
      'ends the session, counts it and shows the sessions again',
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc.add(const SessionEndConfirmed('session-chrome'));
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.endedCount, 1);
        expect(bloc.state.endingId, isNull);
        expect(bloc.state.active.map((s) => s.id), ['session-pixel']);
        expect(bloc.state.failedAction, isNull);
      },
    );

    blocTest<SessionsBloc, SessionsState>(
      'the ended session shows on the Previous tab when it was read already',
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc.add(const SessionsTabSelected(SessionsTab.previous));
        await bloc.stream.firstWhere(
          (s) => s.previousStatus == PreviousStatus.ready,
        );
        bloc.add(const SessionEndConfirmed('session-chrome'));
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.previous, hasLength(4));
        expect(bloc.state.previous.first.id, 'session-chrome');
      },
    );

    blocTest<SessionsBloc, SessionsState>(
      'a failure keeps the session and offers to try again',
      build: build,
      act: (bloc) async {
        await start(bloc);
        demo.update(const DemoSettings(save: DemoSave.fails));
        bloc.add(const SessionEndConfirmed('session-chrome'));
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.endedCount, 0);
        expect(
          bloc.state.failedAction,
          const SessionEndConfirmed('session-chrome'),
        );
        expect(bloc.state.active, hasLength(2));
        expect(bloc.state.endingId, isNull);
      },
    );

    blocTest<SessionsBloc, SessionsState>(
      'trying again once the server answers ends it',
      build: build,
      act: (bloc) async {
        await start(bloc);
        demo.update(const DemoSettings(save: DemoSave.fails));
        bloc.add(const SessionEndConfirmed('session-chrome'));
        await bloc.stream.firstWhere((s) => s.failedAction != null);
        demo.update(const DemoSettings());
        bloc.add(bloc.state.failedAction!);
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.endedCount, 1);
        expect(bloc.state.failedAction, isNull);
      },
    );
  });

  group('SessionsRefreshed', () {
    blocTest<SessionsBloc, SessionsState>(
      'shows what changed without going through loading',
      build: build,
      act: (bloc) async {
        await start(bloc);
        await repository.endOthers(password: 'x');
        bloc.add(const SessionsRefreshed());
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.status, SessionsStatus.ready);
        expect(bloc.state.active, hasLength(1));
        expect(bloc.state.others, isEmpty);
      },
    );

    blocTest<SessionsBloc, SessionsState>(
      'reads the data again when the demo panel changes it',
      build: build,
      act: (bloc) async {
        await start(bloc);
        demo.update(const DemoSettings(scenario: DemoScenario.empty));
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) => expect(bloc.state.active, hasLength(1)),
    );
  });
}
