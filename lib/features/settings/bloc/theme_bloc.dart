import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:money_scribe/features/settings/domain/theme_choice.dart';
import 'package:money_scribe/features/settings/domain/theme_repository.dart';

part 'theme_event.dart';
part 'theme_state.dart';

/// The theme of the app: the saved choice, changed from the Settings screen.
class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  new({required ThemeRepository repository})
    : _repository = repository,
      super(ThemeState(repository.read())) {
    // One at a time, so the saved choice is always the last one made.
    on<ThemeSelected>(_onSelected, transformer: sequential());
  }

  final ThemeRepository _repository;

  /// Switches the colours at once, then saves the choice.
  Future<void> _onSelected(
    ThemeSelected event,
    Emitter<ThemeState> emit,
  ) async {
    // Already shown, so already saved.
    if (event.choice == state.choice) return;
    emit(ThemeState(event.choice));
    await _repository.write(event.choice);
  }
}
