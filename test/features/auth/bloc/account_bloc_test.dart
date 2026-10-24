import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/features/auth/bloc/account_bloc.dart';
import 'package:money_scribe/features/auth/data/fake/fake_auth_repository.dart';

import '../../../support/fake_ticker.dart';
import '../../../support/instant_app_lock_repository.dart';

void main() {
  late DemoController demo;
  late FakeAuthRepository repository;
  late FakeTicker ticker;
  late InstantAppLockRepository appLock;

  setUp(() {
    appLock = InstantAppLockRepository(pin: '1234');
    demo = DemoController(latency: Duration.zero);
    repository = FakeAuthRepository(demo: demo, signedIn: true);
    ticker = FakeTicker();
  });

  AccountBloc build() {
    return AccountBloc(
      repository: repository,
      appLock: appLock,
      ticker: ticker,
    );
  }

  Future<void> start(AccountBloc bloc) async {
    bloc.add(const AccountStarted());
    await Future<void>.delayed(Duration.zero);
  }

  group('AccountStarted', () {
    blocTest<AccountBloc, AccountState>(
      'loads the name and the email',
      build: build,
      act: (bloc) => bloc.add(const AccountStarted()),
      verify: (bloc) {
        expect(bloc.state.status, AccountStatus.ready);
        expect(bloc.state.profile?.name, 'Alex');
        expect(bloc.state.profile?.email, 'alex@example.com');
        expect(bloc.state.profile?.initial, 'A');
      },
    );

    blocTest<AccountBloc, AccountState>(
      'reports no connection',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.noConnection)),
      build: build,
      act: (bloc) => bloc.add(const AccountStarted()),
      verify: (bloc) => expect(bloc.state.status, AccountStatus.noConnection),
    );

    blocTest<AccountBloc, AccountState>(
      'reports a server failure and the error',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.error)),
      build: build,
      act: (bloc) => bloc.add(const AccountStarted()),
      errors: () => [isA<Exception>()],
      verify: (bloc) => expect(bloc.state.status, AccountStatus.failure),
    );

    blocTest<AccountBloc, AccountState>(
      'loads again after Try again',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.noConnection)),
      build: build,
      act: (bloc) async {
        await start(bloc);
        demo.update(const DemoSettings());
        bloc.add(const AccountRetried());
      },
      verify: (bloc) => expect(bloc.state.status, AccountStatus.ready),
    );
  });

  group('SignOutConfirmed', () {
    blocTest<AccountBloc, AccountState>(
      'signs the person out',
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc.add(const SignOutConfirmed());
      },
      verify: (bloc) {
        expect(repository.isSignedIn, isFalse);
        expect(bloc.state.action, AccountAction.none);
      },
    );
  });

  group('DeleteAccountConfirmed', () {
    blocTest<AccountBloc, AccountState>(
      'deletes the account and signs out',
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc.add(const DeleteAccountConfirmed('secret'));
      },
      verify: (bloc) {
        expect(bloc.state.action, AccountAction.deleted);
        expect(repository.isSignedIn, isFalse);
      },
    );

    blocTest<AccountBloc, AccountState>(
      'the lock of the deleted account goes with it',
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc.add(const DeleteAccountConfirmed('secret'));
      },
      verify: (_) => expect(appLock.pin, isNull),
    );

    blocTest<AccountBloc, AccountState>(
      'a wrong password keeps the lock too',
      build: build,
      act: (bloc) async {
        await start(bloc);
        demo.update(const DemoSettings(signIn: DemoSignIn.wrongPassword));
        bloc.add(const DeleteAccountConfirmed('nope'));
      },
      verify: (_) => expect(appLock.pin, '1234'),
    );

    blocTest<AccountBloc, AccountState>(
      'signing out keeps the lock',
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc.add(const SignOutConfirmed());
      },
      verify: (_) {
        expect(repository.isSignedIn, isFalse);
        expect(appLock.pin, '1234');
      },
    );

    blocTest<AccountBloc, AccountState>(
      'a wrong password keeps the account',
      build: build,
      act: (bloc) async {
        await start(bloc);
        demo.update(const DemoSettings(signIn: DemoSignIn.wrongPassword));
        bloc.add(const DeleteAccountConfirmed('nope'));
      },
      verify: (bloc) {
        expect(bloc.state.action, AccountAction.wrongPassword);
        expect(repository.isSignedIn, isTrue);
      },
    );

    blocTest<AccountBloc, AccountState>(
      'no connection keeps the account',
      build: build,
      act: (bloc) async {
        await start(bloc);
        demo.update(const DemoSettings(scenario: DemoScenario.noConnection));
        bloc.add(const DeleteAccountConfirmed('secret'));
      },
      verify: (bloc) {
        expect(bloc.state.action, AccountAction.deleteFailed);
        expect(repository.isSignedIn, isTrue);
      },
    );

    blocTest<AccountBloc, AccountState>(
      'a server failure keeps the account and reports the error',
      build: build,
      act: (bloc) async {
        await start(bloc);
        demo.update(const DemoSettings(scenario: DemoScenario.error));
        bloc.add(const DeleteAccountConfirmed('secret'));
      },
      errors: () => [isA<Exception>()],
      verify: (bloc) => expect(bloc.state.action, AccountAction.deleteFailed),
    );

    blocTest<AccountBloc, AccountState>(
      'a lock after wrong passwords is a wait the server gave, counted down',
      build: build,
      act: (bloc) async {
        await start(bloc);
        demo.update(
          const DemoSettings(passwordChange: DemoPasswordChange.locked),
        );
        bloc.add(const DeleteAccountConfirmed('secret'));
        await pumpEventQueue();
        ticker.tick(899);
        await pumpEventQueue();
        ticker.tick(0);
      },
      // Loading, ready and deleting come first.
      skip: 3,
      expect: () => [
        isA<AccountState>()
            .having((s) => s.action, 'action', AccountAction.deleteWaiting)
            .having((s) => s.deleteWaitSecondsLeft, 'left', 900),
        isA<AccountState>()
            .having((s) => s.action, 'action', AccountAction.deleteWaiting)
            .having((s) => s.deleteWaitSecondsLeft, 'left', 899),
        isA<AccountState>()
            .having((s) => s.action, 'action', AccountAction.none)
            .having((s) => s.deleteWaitSecondsLeft, 'left', 0),
      ],
      verify: (bloc) {
        expect(ticker.started, [900]);
        expect(repository.isSignedIn, isTrue);
      },
    );

    blocTest<AccountBloc, AccountState>(
      'during the wait nothing is sent, and opening the dialog keeps the wait',
      build: build,
      act: (bloc) async {
        await start(bloc);
        demo.update(
          const DemoSettings(passwordChange: DemoPasswordChange.locked),
        );
        bloc.add(const DeleteAccountConfirmed('secret'));
        await pumpEventQueue();
        demo.update(const DemoSettings());
        bloc
          ..add(const DeleteAccountDialogOpened())
          ..add(const DeleteAccountConfirmed('secret'));
        await pumpEventQueue();
      },
      verify: (bloc) {
        expect(bloc.state.action, AccountAction.deleteWaiting);
        expect(bloc.state.deleteWaitSecondsLeft, 900);
        expect(repository.isSignedIn, isTrue);
        expect(ticker.started, [900]);
      },
    );

    blocTest<AccountBloc, AccountState>(
      'a busy server keeps the account',
      build: build,
      act: (bloc) async {
        await start(bloc);
        demo.update(
          const DemoSettings(passwordChange: DemoPasswordChange.unavailable),
        );
        bloc.add(const DeleteAccountConfirmed('secret'));
      },
      verify: (bloc) {
        expect(bloc.state.action, AccountAction.deleteUnavailable);
        expect(repository.isSignedIn, isTrue);
      },
    );

    blocTest<AccountBloc, AccountState>(
      'opening the dialog again forgets the last answer',
      build: build,
      act: (bloc) async {
        await start(bloc);
        demo.update(const DemoSettings(signIn: DemoSignIn.wrongPassword));
        bloc.add(const DeleteAccountConfirmed('nope'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const DeleteAccountDialogOpened());
      },
      verify: (bloc) => expect(bloc.state.action, AccountAction.none),
    );
  });
}
