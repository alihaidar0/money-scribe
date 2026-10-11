import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/features/settings/bloc/language_bloc.dart';
import 'package:money_scribe/features/settings/domain/app_language.dart';

import '../../../support/fake_language_repository.dart';

void main() {
  test('starts with the saved language', () {
    final bloc = LanguageBloc(
      repository: FakeLanguageRepository(AppLanguage.arabic),
    );
    addTearDown(bloc.close);

    expect(bloc.state, const LanguageState(AppLanguage.arabic));
  });

  group('LanguageSelected', () {
    late FakeLanguageRepository repository;

    setUp(() => repository = FakeLanguageRepository());

    blocTest<LanguageBloc, LanguageState>(
      'switches to the language and saves it',
      build: () => LanguageBloc(repository: repository),
      act: (bloc) => bloc.add(const LanguageSelected(AppLanguage.english)),
      expect: () => [const LanguageState(AppLanguage.english)],
      verify: (_) => expect(repository.language, AppLanguage.english),
    );

    blocTest<LanguageBloc, LanguageState>(
      'saves the last choice when several come in a row',
      build: () => LanguageBloc(repository: repository),
      act: (bloc) => bloc
        ..add(const LanguageSelected(AppLanguage.english))
        ..add(const LanguageSelected(AppLanguage.arabic)),
      expect: () => [
        const LanguageState(AppLanguage.english),
        const LanguageState(AppLanguage.arabic),
      ],
      verify: (_) => expect(repository.language, AppLanguage.arabic),
    );

    blocTest<LanguageBloc, LanguageState>(
      'choosing the language already shown changes nothing',
      build: () => LanguageBloc(repository: repository),
      act: (bloc) => bloc.add(const LanguageSelected(AppLanguage.system)),
      expect: () => <LanguageState>[],
    );
  });
}
