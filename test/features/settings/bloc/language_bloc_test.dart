import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/features/settings/bloc/language_bloc.dart';
import 'package:money_scribe/features/settings/domain/app_language.dart';

import '../../../support/fake_account_locale_repository.dart';
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
  group('the account', () {
    blocTest<LanguageBloc, LanguageState>(
      'hears about a language change',
      build: () {
        final account = FakeAccountLocaleRepository();
        addTearDown(() => expect(account.syncs, 1));
        return LanguageBloc(
          repository: FakeLanguageRepository(),
          accountLocale: account,
        );
      },
      act: (bloc) => bloc.add(const LanguageSelected(AppLanguage.arabic)),
      expect: () => [const LanguageState(AppLanguage.arabic)],
    );

    blocTest<LanguageBloc, LanguageState>(
      'is not told when the language is already shown',
      build: () {
        final account = FakeAccountLocaleRepository();
        addTearDown(() => expect(account.syncs, 0));
        return LanguageBloc(
          repository: FakeLanguageRepository(),
          accountLocale: account,
        );
      },
      act: (bloc) => bloc.add(const LanguageSelected(AppLanguage.system)),
      expect: () => <LanguageState>[],
    );

    blocTest<LanguageBloc, LanguageState>(
      'a server that cannot be reached does not undo the choice',
      build: () => LanguageBloc(
        repository: FakeLanguageRepository(),
        accountLocale: FakeAccountLocaleRepository(
          failure: const NoConnectionException(),
        ),
      ),
      act: (bloc) => bloc.add(const LanguageSelected(AppLanguage.arabic)),
      expect: () => [const LanguageState(AppLanguage.arabic)],
      errors: () => <Matcher>[],
    );
  });
}
