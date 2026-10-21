import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/features/auth/bloc/account_bloc.dart';
import 'package:money_scribe/features/auth/data/fake/fake_auth_repository.dart';

import '../../../support/not_available_auth_repository.dart';

void main() {
  late DemoController demo;
  late FakeAuthRepository repository;

  setUp(() {
    demo = DemoController(latency: Duration.zero);
    repository = FakeAuthRepository(demo: demo, signedIn: true);
  });

  AccountBloc build() => AccountBloc(repository: repository);

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

  blocTest<AccountBloc, AccountState>(
    'deleting the account says so when the server does not offer it yet',
    build: () => AccountBloc(
      repository: NotAvailableAuthRepository(
        demo: DemoController(latency: Duration.zero),
        signedIn: true,
      ),
    ),
    act: (bloc) => bloc.add(const DeleteAccountConfirmed('secret')),
    verify: (bloc) =>
        expect(bloc.state.action, AccountAction.deleteNotAvailable),
  );
}
