import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/features/auth/domain/auth_repository.dart';

part 'new_password_event.dart';
part 'new_password_state.dart';

/// The New password screen: checks that the two fields are the same text as
/// they are typed, and saves the password. The app applies no other rule: the
/// server owns the password policy.
class NewPasswordBloc extends Bloc<NewPasswordEvent, NewPasswordState> {
  new({required this._repository}) : super(const NewPasswordState()) {
    on<NewPasswordChanged>(_onChanged, transformer: sequential());
    // A second press while the first is being saved is ignored.
    on<NewPasswordSubmitted>(_onSubmitted, transformer: droppable());
  }

  final AuthRepository _repository;

  void _onChanged(NewPasswordChanged event, Emitter<NewPasswordState> emit) {
    emit(
      NewPasswordState(
        matches:
            event.password.isNotEmpty && event.password == event.confirmation,
        mismatch:
            event.confirmation.isNotEmpty &&
            event.confirmation != event.password,
      ),
    );
  }

  Future<void> _onSubmitted(
    NewPasswordSubmitted event,
    Emitter<NewPasswordState> emit,
  ) async {
    if (!state.isValid) return;
    emit(state.copyWith(status: NewPasswordStatus.saving));
    try {
      await _repository.resetPassword(event.password);
      emit(state.copyWith(status: NewPasswordStatus.saved));
    } on FeatureNotAvailableException {
      emit(state.copyWith(status: NewPasswordStatus.notAvailable));
    } on NoConnectionException {
      emit(state.copyWith(status: NewPasswordStatus.noConnection));
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.copyWith(status: NewPasswordStatus.failure));
    }
  }
}
