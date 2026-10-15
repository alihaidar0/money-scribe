import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/features/settings/bloc/theme_bloc.dart';
import 'package:money_scribe/features/settings/domain/theme_choice.dart';

import '../../../support/fake_theme_repository.dart';

void main() {
  test('starts with the saved theme', () {
    final bloc = ThemeBloc(repository: FakeThemeRepository(ThemeChoice.dark));
    addTearDown(bloc.close);

    expect(bloc.state.choice, ThemeChoice.dark);
  });

  test('follows the system when nothing was saved', () {
    final bloc = ThemeBloc(repository: FakeThemeRepository());
    addTearDown(bloc.close);

    expect(bloc.state.choice, ThemeChoice.system);
  });

  blocTest<ThemeBloc, ThemeState>(
    'switches at once and saves the choice',
    build: () => ThemeBloc(repository: repository),
    act: (bloc) => bloc
      ..add(const ThemeSelected(ThemeChoice.dark))
      ..add(const ThemeSelected(ThemeChoice.light)),
    expect: () => const [
      ThemeState(ThemeChoice.dark),
      ThemeState(ThemeChoice.light),
    ],
    verify: (_) => expect(repository.choice, ThemeChoice.light),
  );

  blocTest<ThemeBloc, ThemeState>(
    'ignores the choice that is already shown',
    build: () => ThemeBloc(repository: FakeThemeRepository(ThemeChoice.dark)),
    act: (bloc) => bloc.add(const ThemeSelected(ThemeChoice.dark)),
    expect: () => <ThemeState>[],
  );
}

final repository = FakeThemeRepository();
