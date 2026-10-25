import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/features/auth/bloc/edit_name_bloc.dart';
import 'package:money_scribe/features/auth/data/fake/fake_auth_repository.dart';
import 'package:money_scribe/features/auth/domain/account_profile.dart';

void main() {
  late DemoController demo;
  late FakeAuthRepository repository;

  setUp(() {
    demo = DemoController(latency: Duration.zero);
    repository = FakeAuthRepository(demo: demo, signedIn: true);
  });

  EditNameBloc build() {
    return EditNameBloc(repository: repository, currentName: 'Alex');
  }

  Future<void> save(EditNameBloc bloc, String name) async {
    bloc.add(EditNameChanged(name));
    await pumpEventQueue();
    bloc.add(const EditNameSubmitted());
    await pumpEventQueue();
  }

  test('starts with the current name and cannot be saved', () {
    final bloc = build();
    addTearDown(bloc.close);

    expect(bloc.state.name, 'Alex');
    expect(bloc.state.canSave, isFalse);
  });

  group('what can be saved', () {
    blocTest<EditNameBloc, EditNameState>(
      'a different name can',
      build: build,
      act: (bloc) => bloc.add(const EditNameChanged('Dana')),
      verify: (bloc) => expect(bloc.state.canSave, isTrue),
    );

    blocTest<EditNameBloc, EditNameState>(
      'the same name, spaces aside, cannot',
      build: build,
      act: (bloc) => bloc.add(const EditNameChanged('  Alex ')),
      verify: (bloc) => expect(bloc.state.canSave, isFalse),
    );

    blocTest<EditNameBloc, EditNameState>(
      'an empty name, or spaces only, cannot',
      build: build,
      act: (bloc) => bloc.add(const EditNameChanged('   ')),
      verify: (bloc) => expect(bloc.state.canSave, isFalse),
    );
  });

  group('EditNameSubmitted', () {
    blocTest<EditNameBloc, EditNameState>(
      'saves the name and answers the profile with it',
      build: build,
      act: (bloc) => save(bloc, '  Dana  '),
      verify: (bloc) {
        expect(bloc.state.status, EditNameStatus.saved);
        expect(
          bloc.state.profile,
          const AccountProfile(name: 'Dana', email: 'alex@example.com'),
        );
      },
    );

    blocTest<EditNameBloc, EditNameState>(
      'does nothing while the name cannot be saved',
      build: build,
      act: (bloc) => bloc.add(const EditNameSubmitted()),
      expect: () => <EditNameState>[],
    );

    blocTest<EditNameBloc, EditNameState>(
      'a name the server refuses is explained, and typing starts a new try',
      build: build,
      act: (bloc) async {
        await save(bloc, 'x' * (FakeAuthRepository.demoMaximumNameLength + 1));
        expect(bloc.state.status, EditNameStatus.rejected);
        bloc.add(const EditNameChanged('Dana'));
      },
      verify: (bloc) {
        expect(bloc.state.status, EditNameStatus.editing);
        expect(bloc.state.issue, isNull);
      },
    );

    blocTest<EditNameBloc, EditNameState>(
      'reports no connection and keeps what was typed',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.noConnection)),
      build: build,
      act: (bloc) => save(bloc, 'Dana'),
      verify: (bloc) {
        expect(bloc.state.status, EditNameStatus.noConnection);
        expect(bloc.state.name, 'Dana');
      },
    );

    blocTest<EditNameBloc, EditNameState>(
      'reports a server failure and the error',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.error)),
      build: build,
      act: (bloc) => save(bloc, 'Dana'),
      errors: () => [isA<Exception>()],
      verify: (bloc) => expect(bloc.state.status, EditNameStatus.failure),
    );
  });
}
