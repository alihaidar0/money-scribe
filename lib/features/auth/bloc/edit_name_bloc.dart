import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/features/auth/domain/account_profile.dart';
import 'package:money_scribe/features/auth/domain/auth_exception.dart';
import 'package:money_scribe/features/auth/domain/auth_repository.dart';

part 'edit_name_event.dart';
part 'edit_name_state.dart';

/// The Edit name dialog: the name as it is typed, and saving it. The app only
/// stops a name that is empty or unchanged; the server decides what else is
/// acceptable and says why when it refuses.
class EditNameBloc extends Bloc<EditNameEvent, EditNameState> {
  new({required this._repository, required String currentName})
    : super(EditNameState(currentName: currentName, name: currentName)) {
    on<EditNameChanged>(_onChanged, transformer: sequential());
    // A second press while the first is being saved is ignored.
    on<EditNameSubmitted>(_onSubmitted, transformer: droppable());
  }

  final AuthRepository _repository;

  void _onChanged(EditNameChanged event, Emitter<EditNameState> emit) {
    // Typing after a refusal or a failure starts a new try.
    emit(EditNameState(currentName: state.currentName, name: event.name));
  }

  Future<void> _onSubmitted(
    EditNameSubmitted event,
    Emitter<EditNameState> emit,
  ) async {
    if (!state.canSave) return;
    emit(state.copyWith(status: EditNameStatus.saving));
    try {
      final profile = await _repository.updateName(state.name);
      emit(state.copyWith(status: EditNameStatus.saved, profile: profile));
    } on NameRejectedException catch (error) {
      emit(state.copyWith(status: EditNameStatus.rejected, issue: error.issue));
    } on ServiceUnavailableException {
      emit(state.copyWith(status: EditNameStatus.unavailable));
    } on NoConnectionException {
      emit(state.copyWith(status: EditNameStatus.noConnection));
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.copyWith(status: EditNameStatus.failure));
    }
  }
}
