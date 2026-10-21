import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/features/connection/bloc/server_wake_bloc.dart';

import '../../../support/fake_server_activity.dart';

void main() {
  late FakeServerActivity activity;

  setUp(() => activity = FakeServerActivity());

  ServerWakeBloc build() => ServerWakeBloc(activity: activity);

  test('starts quiet when the server is not slow', () {
    final bloc = build();
    addTearDown(bloc.close);

    expect(bloc.state, const ServerWakeState());
  });

  test('starts waking when the server is already slow', () {
    activity.setSlow(value: true);
    final bloc = build();
    addTearDown(bloc.close);

    expect(bloc.state, const ServerWakeState(isWaking: true));
  });

  blocTest<ServerWakeBloc, ServerWakeState>(
    'follows the server: waking, then quiet',
    build: build,
    act: (bloc) async {
      bloc.add(const ServerWakeStarted());
      await pumpEventQueue();
      activity.setSlow(value: true);
      await pumpEventQueue();
      activity.setSlow(value: false);
    },
    expect: () => const [ServerWakeState(isWaking: true), ServerWakeState()],
  );

  blocTest<ServerWakeBloc, ServerWakeState>(
    'listens only once, however often it is told to start',
    build: build,
    act: (bloc) async {
      bloc
        ..add(const ServerWakeStarted())
        ..add(const ServerWakeStarted());
      await pumpEventQueue();
      activity.setSlow(value: true);
    },
    expect: () => const [ServerWakeState(isWaking: true)],
  );

  blocTest<ServerWakeBloc, ServerWakeState>(
    'says nothing before it is started',
    build: build,
    act: (bloc) => activity.setSlow(value: true),
    expect: () => <ServerWakeState>[],
  );
}
