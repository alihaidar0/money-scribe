import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/features/settings/domain/account_locale_repository.dart';
import 'package:money_scribe/features/settings/domain/app_language.dart';
import 'package:money_scribe/features/settings/domain/language_repository.dart';

part 'language_event.dart';
part 'language_state.dart';

/// The app language: the saved choice, changed from the Settings screen.
class LanguageBloc extends Bloc<LanguageEvent, LanguageState> {
  new({required LanguageRepository repository, this._accountLocale})
    : _repository = repository,
      super(LanguageState(repository.read())) {
    // One at a time, so the saved choice is always the last one made.
    on<LanguageSelected>(_onSelected, transformer: sequential());
  }

  final LanguageRepository _repository;

  /// Where the account hears about the language, or `null` in a build with no
  /// server.
  final AccountLocaleRepository? _accountLocale;

  /// Switches the language at once, then saves the choice and tells the
  /// account.
  Future<void> _onSelected(
    LanguageSelected event,
    Emitter<LanguageState> emit,
  ) async {
    // Already shown, so already saved.
    if (event.language == state.language) return;
    emit(LanguageState(event.language));
    await _repository.write(event.language);
    // Not awaited: a slow server never holds up the next choice.
    unawaited(_tellAccount());
  }

  Future<void> _tellAccount() async {
    try {
      await _accountLocale?.sync();
    } on DataException {
      // Nothing to do: the language goes again with the next settings change
      // and at the next sign-in. The choice itself is saved on the device.
    }
  }
}
