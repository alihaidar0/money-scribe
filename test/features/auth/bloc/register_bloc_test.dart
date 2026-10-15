import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/features/auth/bloc/register_bloc.dart';
import 'package:money_scribe/features/auth/data/fake/fake_auth_repository.dart';
import 'package:money_scribe/features/auth/domain/auth_exception.dart';

void main() {
  late DemoController demo;
  late FakeAuthRepository auth;

  setUp(() {
    demo = DemoController(latency: Duration.zero);
    auth = FakeAuthRepository(demo: demo);
  });

  RegisterBloc build() => RegisterBloc(repository: auth);

  const submit = RegisterSubmitted(
    name: 'Alex',
    email: 'alex@example.com',
    password: 'secret',
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
    'shows what the server refused',
    setUp: () => demo.update(
      const DemoSettings(registration: DemoRegistration.rejected),
    ),
    build: build,
    act: (bloc) => bloc.add(submit),
    expect: () => [
      const RegisterState(status: RegisterStatus.submitting),
      RegisterState(
        status: RegisterStatus.rejected,
        problems: RegistrationProblem.values.toSet(),
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
