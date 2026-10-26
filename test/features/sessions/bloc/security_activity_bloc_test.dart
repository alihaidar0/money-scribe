import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/features/sessions/bloc/security_activity_bloc.dart';
import 'package:money_scribe/features/sessions/data/fake/fake_sessions_repository.dart';
import 'package:money_scribe/features/sessions/domain/security_event.dart';

void main() {
  late DemoController demo;
  late FakeSessionsRepository repository;

  setUp(() {
    demo = DemoController(latency: Duration.zero);
    repository = FakeSessionsRepository(demo: demo);
  });

  SecurityActivityBloc build() => SecurityActivityBloc(repository: repository);

  Future<void> start(SecurityActivityBloc bloc) async {
    bloc.add(const SecurityActivityStarted());
    await bloc.stream.firstWhere(
      (s) => s.status == SecurityActivityStatus.ready,
    );
  }

  test('starts loading', () {
    final bloc = build();
    addTearDown(bloc.close);

    expect(bloc.state.status, SecurityActivityStatus.loading);
  });

  blocTest<SecurityActivityBloc, SecurityActivityState>(
    'loads the first page, newest first',
    build: build,
    act: (bloc) => bloc.add(const SecurityActivityStarted()),
    verify: (bloc) {
      expect(bloc.state.status, SecurityActivityStatus.ready);
      expect(bloc.state.events.first.id, 'event-export');
      expect(bloc.state.events, hasLength(5));
      expect(bloc.state.next, isNull);
    },
  );

  blocTest<SecurityActivityBloc, SecurityActivityState>(
    'is empty for an account with no activity',
    setUp: () => demo.update(const DemoSettings(scenario: DemoScenario.empty)),
    build: build,
    act: (bloc) => bloc.add(const SecurityActivityStarted()),
    verify: (bloc) {
      expect(bloc.state.status, SecurityActivityStatus.ready);
      expect(bloc.state.events, isEmpty);
    },
  );

  blocTest<SecurityActivityBloc, SecurityActivityState>(
    'reports no connection and loads again on Retry',
    setUp: () =>
        demo.update(const DemoSettings(scenario: DemoScenario.noConnection)),
    build: build,
    act: (bloc) async {
      bloc.add(const SecurityActivityStarted());
      await bloc.stream.firstWhere(
        (s) => s.status == SecurityActivityStatus.noConnection,
      );
      demo.update(const DemoSettings());
      bloc.add(const SecurityActivityRetried());
    },
    wait: const Duration(milliseconds: 50),
    verify: (bloc) => expect(bloc.state.status, SecurityActivityStatus.ready),
  );

  blocTest<SecurityActivityBloc, SecurityActivityState>(
    'reports a server failure and the error',
    setUp: () => demo.update(const DemoSettings(scenario: DemoScenario.error)),
    build: build,
    act: (bloc) => bloc.add(const SecurityActivityStarted()),
    verify: (bloc) => expect(bloc.state.status, SecurityActivityStatus.failure),
    errors: () => [isA<ServerException>()],
  );

  group('the next page', () {
    blocTest<SecurityActivityBloc, SecurityActivityState>(
      'is added after the first',
      setUp: () => repository = FakeSessionsRepository(demo: demo, pageSize: 3),
      build: build,
      act: (bloc) async {
        await start(bloc);
        expect(bloc.state.next, isNotNull);
        bloc.add(const SecurityActivityMoreRequested());
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.events, hasLength(5));
        expect(bloc.state.next, isNull);
        expect(bloc.state.loadingMore, isFalse);
      },
    );

    blocTest<SecurityActivityBloc, SecurityActivityState>(
      'keeps what is shown when it does not load',
      setUp: () => repository = FakeSessionsRepository(demo: demo, pageSize: 3),
      build: build,
      act: (bloc) async {
        await start(bloc);
        demo.update(const DemoSettings(scenario: DemoScenario.noConnection));
        bloc.add(const SecurityActivityMoreRequested());
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.events, hasLength(3));
        expect(bloc.state.loadMoreFailed, isTrue);
      },
    );
  });

  test('puts the imports of one action together in its entries', () {
    final events = [
      SecurityEvent(
        id: '2',
        type: SecurityEventType.dataImported,
        occurredAt: DateTime(2026, 10, 20, 12, 5),
        sessionId: 's',
        count: 3,
      ),
      SecurityEvent(
        id: '1',
        type: SecurityEventType.dataImported,
        occurredAt: DateTime(2026, 10, 20, 12),
        sessionId: 's',
        count: 4,
      ),
    ];
    final state = SecurityActivityState(events: events);

    expect(state.events, hasLength(2));
    expect(state.entries.single.count, 7);
  });

  group('a run of imports at the end of a page', () {
    SecurityEvent import(String id, int minute, {String type = 'import'}) {
      return SecurityEvent(
        id: id,
        type: type == 'import'
            ? SecurityEventType.dataImported
            : SecurityEventType.signedIn,
        occurredAt: DateTime(
          2026,
          10,
          20,
          12,
        ).subtract(Duration(minutes: minute)),
        sessionId: 's',
        count: 1,
      );
    }

    blocTest<SecurityActivityBloc, SecurityActivityState>(
      'goes on in the next page, so it is not shown cut in two',
      setUp: () => repository = _OneEntryPages(demo: demo, [
        import('3', 0),
        import('2', 1),
        import('1', 2),
        import('0', 60, type: 'sign-in'),
      ]),
      build: build,
      act: start,
      verify: (bloc) {
        // The page of one entry reached the whole run before it was shown.
        expect(bloc.state.events.map((e) => e.id), ['3', '2', '1', '0']);
        expect(bloc.state.entries.map((e) => e.count), [3, 1]);
      },
    );

    blocTest<SecurityActivityBloc, SecurityActivityState>(
      'does not read more when the page ends on something else',
      setUp: () => repository = _OneEntryPages(demo: demo, [
        import('2', 0, type: 'sign-in'),
        import('1', 1),
      ]),
      build: build,
      act: start,
      verify: (bloc) {
        expect(bloc.state.events.map((e) => e.id), ['2']);
        expect(bloc.state.next, isNotNull);
      },
    );
  });
}

/// The fake sessions whose activity comes one entry to a page.
class _OneEntryPages extends FakeSessionsRepository {
  new(this._events, {required super.demo});

  final List<SecurityEvent> _events;

  @override
  Future<SecurityEventsPage> activity({String? cursor}) async {
    final start = int.tryParse(cursor ?? '') ?? 0;
    return SecurityEventsPage(
      items: [_events[start]],
      nextCursor: start + 1 < _events.length ? '${start + 1}' : null,
    );
  }
}
