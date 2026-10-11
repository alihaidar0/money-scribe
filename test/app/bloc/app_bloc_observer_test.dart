import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/app/bloc/app_bloc_observer.dart';
import 'package:money_scribe/features/settings/bloc/language_bloc.dart';
import 'package:money_scribe/features/settings/domain/app_language.dart';

import '../../support/fake_language_repository.dart';

/// Stands in for the observer the Bloc library uses when none is set.
class _SilentObserver extends BlocObserver {
  const new();
}

void main() {
  late List<String> logs;
  late DebugPrintCallback originalDebugPrint;

  setUp(() {
    logs = [];
    originalDebugPrint = debugPrint;
    debugPrint = (message, {wrapWidth}) => logs.add(message ?? '');
    Bloc.observer = const AppBlocObserver();
  });

  tearDown(() {
    debugPrint = originalDebugPrint;
    Bloc.observer = const _SilentObserver();
  });

  test('logs the type of an event, never its contents', () async {
    final bloc = LanguageBloc(repository: FakeLanguageRepository());
    addTearDown(bloc.close);

    bloc.add(const LanguageSelected(AppLanguage.arabic));
    await bloc.stream.first;

    expect(logs, ['LanguageBloc received LanguageSelected']);
    expect(logs.join(), isNot(contains('arabic')));
  });

  test('logs the type of an error, never its message', () {
    final bloc = LanguageBloc(repository: FakeLanguageRepository());
    addTearDown(bloc.close);

    const AppBlocObserver().onError(
      bloc,
      Exception('secret detail'),
      StackTrace.empty,
    );

    expect(logs, ['LanguageBloc failed with _Exception']);
  });
}
