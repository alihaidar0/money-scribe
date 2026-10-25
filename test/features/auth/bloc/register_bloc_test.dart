import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/features/auth/bloc/register_bloc.dart';
import 'package:money_scribe/features/auth/data/fake/fake_auth_repository.dart';
import 'package:money_scribe/features/auth/domain/password_problem.dart';

import '../../../support/fake_ticker.dart';

/// Remembers the password it was given, to check it is sent as typed.
class _RecordingAuth extends FakeAuthRepository {
  new({required super.demo});

  String? password;

  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) {
    this.password = password;
    return super.register(name: name, email: email, password: password);
  }
}

void main() {
  late DemoController demo;
  late FakeAuthRepository auth;
  late FakeTicker ticker;

  setUp(() {
    demo = DemoController(latency: Duration.zero);
    auth = FakeAuthRepository(demo: demo);
    ticker = FakeTicker();
  });

  RegisterBloc build() => RegisterBloc(repository: auth, ticker: ticker);

  const submit = RegisterSubmitted(
    name: 'Alex',
    email: 'alex@example.com',
    password: 'secret',
    confirmation: 'secret',
  );

  blocTest<RegisterBloc, RegisterState>(
    'creates the account from any data',
    build: build,
    act: (bloc) => bloc.add(submit),
    expect: () => const [
      RegisterState(status: RegisterStatus.submitting),
      RegisterState(status: RegisterStatus.success),
    ],
    verify: (_) => expect(auth.pendingEmail, 'alex@example.com'),
  );

  blocTest<RegisterBloc, RegisterState>(
    'sends the password exactly as typed, spaces included',
    build: () {
      final recording = _RecordingAuth(demo: demo);
      auth = recording;
      return build();
    },
    act: (bloc) => bloc.add(
      const RegisterSubmitted(
        name: 'Alex',
        email: 'alex@example.com',
        password: '  a long pass phrase  ',
        confirmation: '  a long pass phrase  ',
      ),
    ),
    verify: (_) =>
        expect((auth as _RecordingAuth).password, '  a long pass phrase  '),
  );

  group('the two password fields', () {
    blocTest<RegisterBloc, RegisterState>(
      'that differ are refused without asking the server',
      build: build,
      act: (bloc) => bloc.add(
        const RegisterSubmitted(
          name: 'Alex',
          email: 'new@b.c',
          password: 'one',
          confirmation: 'two',
        ),
      ),
      expect: () => const [
        RegisterState(
          status: RegisterStatus.rejected,
          passwordsDoNotMatch: true,
        ),
      ],
      // Nothing was sent: the sample address is still the pending one.
      verify: (_) => expect(auth.pendingEmail, 'alex@example.com'),
    );

    blocTest<RegisterBloc, RegisterState>(
      'that differ only in a space are different passwords',
      build: build,
      act: (bloc) => bloc.add(
        const RegisterSubmitted(
          name: 'Alex',
          email: 'new@b.c',
          password: 'one ',
          confirmation: 'one',
        ),
      ),
      expect: () => const [
        RegisterState(
          status: RegisterStatus.rejected,
          passwordsDoNotMatch: true,
        ),
      ],
    );

    blocTest<RegisterBloc, RegisterState>(
      'that are the same, however short, are sent: the server judges them',
      build: build,
      act: (bloc) => bloc.add(
        const RegisterSubmitted(
          name: 'Alex',
          email: 'new@b.c',
          password: 'x',
          confirmation: 'x',
        ),
      ),
      expect: () => const [
        RegisterState(status: RegisterStatus.submitting),
        RegisterState(status: RegisterStatus.success),
      ],
    );
  });

  blocTest<RegisterBloc, RegisterState>(
    'shows what the server refused',
    setUp: () => demo.update(
      const DemoSettings(registration: DemoRegistration.rejected),
    ),
    build: build,
    act: (bloc) => bloc.add(submit),
    expect: () => const [
      RegisterState(status: RegisterStatus.submitting),
      RegisterState(
        status: RegisterStatus.rejected,
        passwordProblem: PasswordProblem(
          PasswordIssue.tooShort,
          limit: FakeAuthRepository.demoMinimumPasswordLength,
        ),
        emailInvalid: true,
      ),
    ],
  );

  blocTest<RegisterBloc, RegisterState>(
    'a new attempt clears the errors',
    setUp: () => demo.update(
      const DemoSettings(registration: DemoRegistration.rejected),
    ),
    build: build,
    act: (bloc) async {
      bloc.add(submit);
      await pumpEventQueue();
      demo.update(const DemoSettings());
      bloc.add(submit);
    },
    skip: 2,
    expect: () => const [
      RegisterState(status: RegisterStatus.submitting),
      RegisterState(status: RegisterStatus.success),
    ],
  );

  group('when the server asks to wait', () {
    Future<RegisterBloc> waitingBloc() async {
      demo.update(const DemoSettings(registration: DemoRegistration.tooSoon));
      final bloc = build();
      addTearDown(bloc.close);
      bloc.add(submit);
      await bloc.stream.firstWhere(
        (state) => state.status == RegisterStatus.waiting,
      );
      return bloc;
    }

    blocTest<RegisterBloc, RegisterState>(
      'counts down from the time the server gave',
      setUp: () => demo.update(
        const DemoSettings(registration: DemoRegistration.tooSoon),
      ),
      build: build,
      act: (bloc) => bloc.add(submit),
      expect: () => const [
        RegisterState(status: RegisterStatus.submitting),
        RegisterState(status: RegisterStatus.waiting, waitSecondsLeft: 60),
      ],
      verify: (_) => expect(ticker.started, [60]),
    );

    test('ticks the button down, and frees it at zero', () async {
      final bloc = await waitingBloc();

      ticker.tick(41);
      await pumpEventQueue();
      expect(
        bloc.state,
        const RegisterState(
          status: RegisterStatus.waiting,
          waitSecondsLeft: 41,
        ),
      );

      ticker.tick(0);
      await pumpEventQueue();
      expect(bloc.state, const RegisterState());
    });

    test('ignores a press while it waits', () async {
      final bloc = await waitingBloc();
      final before = bloc.state;

      bloc.add(submit);
      await pumpEventQueue();

      expect(bloc.state, before);
      expect(ticker.started, [60]);
    });

    test('can be sent again once the wait is over', () async {
      final bloc = await waitingBloc();
      ticker.tick(0);
      await pumpEventQueue();
      demo.update(const DemoSettings());

      bloc.add(submit);
      await pumpEventQueue();

      expect(bloc.state.status, RegisterStatus.success);
    });
  });

  blocTest<RegisterBloc, RegisterState>(
    'asks to try again shortly when the server is busy',
    setUp: () => demo.update(
      const DemoSettings(registration: DemoRegistration.unavailable),
    ),
    build: build,
    act: (bloc) => bloc.add(submit),
    expect: () => const [
      RegisterState(status: RegisterStatus.submitting),
      RegisterState(status: RegisterStatus.unavailable),
    ],
  );

  blocTest<RegisterBloc, RegisterState>(
    'reports no connection',
    setUp: () =>
        demo.update(const DemoSettings(scenario: DemoScenario.noConnection)),
    build: build,
    act: (bloc) => bloc.add(submit),
    expect: () => const [
      RegisterState(status: RegisterStatus.submitting),
      RegisterState(status: RegisterStatus.noConnection),
    ],
  );

  blocTest<RegisterBloc, RegisterState>(
    'reports a server failure and the error',
    setUp: () => demo.update(const DemoSettings(scenario: DemoScenario.error)),
    build: build,
    act: (bloc) => bloc.add(submit),
    expect: () => const [
      RegisterState(status: RegisterStatus.submitting),
      RegisterState(status: RegisterStatus.failure),
    ],
    errors: () => [isA<ServerException>()],
  );
}
