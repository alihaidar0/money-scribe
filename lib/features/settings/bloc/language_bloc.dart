import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:money_scribe/features/settings/domain/app_language.dart';
import 'package:money_scribe/features/settings/domain/language_repository.dart';

part 'language_event.dart';
part 'language_state.dart';

/// The app language: the saved choice, changed from the Settings screen.
class LanguageBloc extends Bloc<LanguageEvent, LanguageState> {
  new({required LanguageRepository repository})
    : _repository = repository,
      super(LanguageState(repository.read())) {
    // One at a time, so the saved choice is always the last one made.
    on<LanguageSelected>(_onSelected, transformer: sequential());
  }

  final LanguageRepository _repository;

  /// Switches the language at once, then saves the choice.
  Future<void> _onSelected(
    LanguageSelected event,
    Emitter<LanguageState> emit,
  ) async {
    // Already shown, so already saved.
    if (event.language == state.language) return;
    emit(LanguageState(event.language));
    await _repository.write(event.language);
  }
}
