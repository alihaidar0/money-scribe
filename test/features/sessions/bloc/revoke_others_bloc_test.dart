import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/features/sessions/bloc/revoke_others_bloc.dart';
import 'package:money_scribe/features/sessions/data/fake/fake_sessions_repository.dart';
import 'package:money_scribe/features/sessions/domain/sessions_repository.dart';

import '../../../support/fake_ticker.dart';

/// Answers `endOthers` the way a test says.
class _Repository extends FakeSessionsRepository {
  new({required super.demo, required this.onEndOthers});

  final Future<OthersSignedOut> Function() onEndOthers;

  @override
  Future<OthersSignedOut> endOthers({required String password}) =>
      onEndOthers();
}

void main() {
  late DemoController demo;
  late FakeTicker ticker;

  setUp(() {
    demo = DemoController(latency: Duration.zero);
    ticker = FakeTicker();
  });

  RevokeOthersBloc build({FakeSessionsRepository? repository}) {
    return RevokeOthersBloc(
      repository: repository ?? FakeSessionsRepository(demo: demo),
      ticker: ticker,
    );
  }

  RevokeOthersBloc failing(Exception error) {
    return build(
      repository: _Repository(demo: demo, onEndOthers: () async => throw error),
    );
  }

  blocTest<RevokeOthersBloc, RevokeOthersState>(
    'signs the other devices out and says how many',
    build: build,
    act: (bloc) => bloc
      ..add(const RevokeOthersPasswordEdited('secret'))
      ..add(const RevokeOthersSubmitted()),
    wait: const Duration(milliseconds: 20),
    verify: (bloc) {
      expect(bloc.state.status, RevokeOthersStatus.done);
      expect(bloc.state.result?.sessionsEnded, 1);
    },
  );

  blocTest<RevokeOthersBloc, RevokeOthersState>(
    'sends nothing while the password is empty',
    build: build,
    act: (bloc) => bloc.add(const RevokeOthersSubmitted()),
    expect: () => <RevokeOthersState>[],
  );

  blocTest<RevokeOthersBloc, RevokeOthersState>(
    'a wrong password is said, and typing again starts a new try',
    setUp: () =>
        demo.update(const DemoSettings(signIn: DemoSignIn.wrongPassword)),
    build: build,
    act: (bloc) async {
      bloc
        ..add(const RevokeOthersPasswordEdited('nope'))
        ..add(const RevokeOthersSubmitted());
      await bloc.stream.firstWhere(
        (s) => s.status == RevokeOthersStatus.wrongPassword,
      );
      bloc.add(const RevokeOthersPasswordEdited('nope2'));
    },
    verify: (bloc) {
      expect(bloc.state.status, RevokeOthersStatus.editing);
      expect(bloc.state.password, 'nope2');
    },
  );

  group('too many wrong passwords', () {
    blocTest<RevokeOthersBloc, RevokeOthersState>(
      'wait for the time the server gave, counting down',
      build: () =>
          failing(const TooManyRequestsException(Duration(seconds: 3))),
      act: (bloc) async {
        bloc
          ..add(const RevokeOthersPasswordEdited('x'))
          ..add(const RevokeOthersSubmitted());
        await bloc.stream.firstWhere(
          (s) => s.status == RevokeOthersStatus.waiting,
        );
        ticker.tick(2);
      },
      wait: const Duration(milliseconds: 20),
      verify: (bloc) {
        expect(bloc.state.status, RevokeOthersStatus.waiting);
        expect(bloc.state.waitSecondsLeft, 2);
      },
    );

    blocTest<RevokeOthersBloc, RevokeOthersState>(
      'can be tried again when the wait is over',
      build: () =>
          failing(const TooManyRequestsException(Duration(seconds: 3))),
      act: (bloc) async {
        bloc
          ..add(const RevokeOthersPasswordEdited('x'))
          ..add(const RevokeOthersSubmitted());
        await bloc.stream.firstWhere(
          (s) => s.status == RevokeOthersStatus.waiting,
        );
        ticker.tick(0);
      },
      wait: const Duration(milliseconds: 20),
      verify: (bloc) => expect(bloc.state.status, RevokeOthersStatus.editing),
    );

    blocTest<RevokeOthersBloc, RevokeOthersState>(
      'cannot be sent while the wait goes on, and typing does not end it',
      build: () =>
          failing(const TooManyRequestsException(Duration(seconds: 3))),
      act: (bloc) async {
        bloc
          ..add(const RevokeOthersPasswordEdited('x'))
          ..add(const RevokeOthersSubmitted());
        await bloc.stream.firstWhere(
          (s) => s.status == RevokeOthersStatus.waiting,
        );
        bloc
          ..add(const RevokeOthersPasswordEdited('xy'))
          ..add(const RevokeOthersSubmitted());
      },
      wait: const Duration(milliseconds: 20),
      verify: (bloc) {
        expect(bloc.state.status, RevokeOthersStatus.waiting);
        expect(bloc.state.password, 'xy');
        expect(bloc.state.waitSecondsLeft, 3);
      },
    );
  });

  group('failures', () {
    blocTest<RevokeOthersBloc, RevokeOthersState>(
      'no connection',
      build: () => failing(const NoConnectionException()),
      act: (bloc) => bloc
        ..add(const RevokeOthersPasswordEdited('x'))
        ..add(const RevokeOthersSubmitted()),
      wait: const Duration(milliseconds: 20),
      verify: (bloc) =>
          expect(bloc.state.status, RevokeOthersStatus.noConnection),
    );

    blocTest<RevokeOthersBloc, RevokeOthersState>(
      'a busy server',
      build: () => failing(const ServiceUnavailableException()),
      act: (bloc) => bloc
        ..add(const RevokeOthersPasswordEdited('x'))
        ..add(const RevokeOthersSubmitted()),
      wait: const Duration(milliseconds: 20),
      verify: (bloc) =>
          expect(bloc.state.status, RevokeOthersStatus.unavailable),
    );

    blocTest<RevokeOthersBloc, RevokeOthersState>(
      'a failure of the server, with the error',
      build: () => failing(const ServerException()),
      act: (bloc) => bloc
        ..add(const RevokeOthersPasswordEdited('x'))
        ..add(const RevokeOthersSubmitted()),
      wait: const Duration(milliseconds: 20),
      verify: (bloc) => expect(bloc.state.status, RevokeOthersStatus.failure),
      errors: () => [isA<ServerException>()],
    );
  });
}
