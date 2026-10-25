import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/features/auth/bloc/change_email_bloc.dart';
import 'package:money_scribe/features/auth/data/fake/fake_auth_repository.dart';
import 'package:money_scribe/features/auth/domain/auth_exception.dart';

import '../../../support/fake_ticker.dart';

void main() {
  late DemoController demo;
  late FakeAuthRepository repository;
  late FakeTicker ticker;

  setUp(() {
    demo = DemoController(latency: Duration.zero);
    repository = FakeAuthRepository(demo: demo, signedIn: true);
    ticker = FakeTicker();
  });

  ChangeEmailBloc build() {
    return ChangeEmailBloc(repository: repository, ticker: ticker);
  }

  Future<void> send(
    ChangeEmailBloc bloc, {
    String email = 'new@example.com',
    String password = 'secret',
  }) async {
    bloc.add(ChangeEmailEdited(email: email, password: password));
    await pumpEventQueue();
    bloc.add(const ChangeEmailSubmitted());
    await pumpEventQueue();
  }

  group('what can be sent', () {
    test('nothing typed cannot', () {
      final bloc = build();
      addTearDown(bloc.close);

      expect(bloc.state.canSend, isFalse);
    });

    blocTest<ChangeEmailBloc, ChangeEmailState>(
      'an address and a password can',
      build: build,
      act: (bloc) => bloc.add(
        const ChangeEmailEdited(email: 'new@example.com', password: 'x'),
      ),
      verify: (bloc) => expect(bloc.state.canSend, isTrue),
    );

    blocTest<ChangeEmailBloc, ChangeEmailState>(
      'spaces only for the address cannot, but spaces in a password count',
      build: build,
      act: (bloc) async {
        bloc.add(const ChangeEmailEdited(email: '   ', password: 'x'));
        await pumpEventQueue();
        expect(bloc.state.canSend, isFalse);
        bloc.add(const ChangeEmailEdited(email: 'a@b.c', password: ' '));
      },
      verify: (bloc) => expect(bloc.state.canSend, isTrue),
    );
  });

  group('ChangeEmailSubmitted', () {
    blocTest<ChangeEmailBloc, ChangeEmailState>(
      'sends the request, keeps the address and goes to the code',
      build: build,
      act: send,
      verify: (bloc) {
        expect(bloc.state.status, ChangeEmailStatus.sent);
        expect(repository.pendingEmail, 'new@example.com');
      },
    );

    blocTest<ChangeEmailBloc, ChangeEmailState>(
      'does nothing while nothing can be sent',
      build: build,
      act: (bloc) => bloc.add(const ChangeEmailSubmitted()),
      expect: () => <ChangeEmailState>[],
    );

    blocTest<ChangeEmailBloc, ChangeEmailState>(
      'a wrong password is told, and typing starts a new try',
      setUp: () =>
          demo.update(const DemoSettings(signIn: DemoSignIn.wrongPassword)),
      build: build,
      act: (bloc) async {
        await send(bloc);
        expect(bloc.state.status, ChangeEmailStatus.wrongPassword);
        bloc.add(
          const ChangeEmailEdited(email: 'new@example.com', password: 'x'),
        );
      },
      verify: (bloc) => expect(bloc.state.status, ChangeEmailStatus.editing),
    );

    blocTest<ChangeEmailBloc, ChangeEmailState>(
      'an address the server refuses says why',
      build: build,
      act: (bloc) => send(bloc, email: FakeAuthRepository.demoTakenEmail),
      verify: (bloc) {
        expect(bloc.state.status, ChangeEmailStatus.rejected);
        expect(bloc.state.issue, EmailIssue.taken);
      },
    );

    blocTest<ChangeEmailBloc, ChangeEmailState>(
      'the address the account has is refused',
      build: build,
      act: (bloc) => send(bloc, email: 'alex@example.com'),
      verify: (bloc) => expect(bloc.state.issue, EmailIssue.unchanged),
    );

    blocTest<ChangeEmailBloc, ChangeEmailState>(
      'a lock after wrong passwords is a wait the server gave, counted down',
      setUp: () => demo.update(
        const DemoSettings(passwordChange: DemoPasswordChange.locked),
      ),
      build: build,
      act: (bloc) async {
        await send(bloc);
        ticker.tick(899);
        await pumpEventQueue();
        ticker.tick(0);
      },
      skip: 3,
      expect: () => [
        isA<ChangeEmailState>()
            .having((s) => s.status, 'status', ChangeEmailStatus.waiting)
            .having((s) => s.waitSecondsLeft, 'left', 899),
        isA<ChangeEmailState>()
            .having((s) => s.status, 'status', ChangeEmailStatus.editing)
            .having((s) => s.waitSecondsLeft, 'left', 0),
      ],
      verify: (_) => expect(ticker.started, [900]),
    );

    blocTest<ChangeEmailBloc, ChangeEmailState>(
      'nothing is sent during the wait',
      setUp: () => demo.update(
        const DemoSettings(passwordChange: DemoPasswordChange.locked),
      ),
      build: build,
      act: (bloc) async {
        await send(bloc);
        bloc
          ..add(const ChangeEmailEdited(email: 'a@b.co', password: 'x'))
          ..add(const ChangeEmailSubmitted());
        await pumpEventQueue();
      },
      verify: (bloc) {
        expect(bloc.state.status, ChangeEmailStatus.waiting);
        expect(ticker.started, [900]);
      },
    );

    blocTest<ChangeEmailBloc, ChangeEmailState>(
      'reports a busy server',
      setUp: () => demo.update(
        const DemoSettings(passwordChange: DemoPasswordChange.unavailable),
      ),
      build: build,
      act: send,
      verify: (bloc) =>
          expect(bloc.state.status, ChangeEmailStatus.unavailable),
    );

    blocTest<ChangeEmailBloc, ChangeEmailState>(
      'reports no connection and keeps what was typed',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.noConnection)),
      build: build,
      act: send,
      verify: (bloc) {
        expect(bloc.state.status, ChangeEmailStatus.noConnection);
        expect(bloc.state.email, 'new@example.com');
      },
    );

    blocTest<ChangeEmailBloc, ChangeEmailState>(
      'reports a server failure and the error',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.error)),
      build: build,
      act: send,
      errors: () => [isA<Exception>()],
      verify: (bloc) => expect(bloc.state.status, ChangeEmailStatus.failure),
    );
  });
}
