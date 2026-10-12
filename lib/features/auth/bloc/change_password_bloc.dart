import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/features/auth/domain/auth_exception.dart';
import 'package:money_scribe/features/auth/domain/auth_repository.dart';

part 'change_password_event.dart';
part 'change_password_state.dart';

/// The Change password screen: the current password, and a new one typed
/// twice.
class ChangePasswordBloc
    extends Bloc<ChangePasswordEvent, ChangePasswordState> {
  new({required this._repository}) : super(const ChangePasswordState()) {
    on<ChangePasswordEdited>(_onEdited, transformer: sequential());
    // A second press while the first is being saved is ignored.
    on<ChangePasswordSubmitted>(_onSubmitted, transformer: droppable());
  }

  /// The fewest characters a password may have.
  static const minLength = 8;

  final AuthRepository _repository;

  void _onEdited(
    ChangePasswordEdited event,
    Emitter<ChangePasswordState> emit,
  ) {
    // Typing after a refusal starts a new try.
    emit(
      ChangePasswordState(
        current: event.current,
        next: event.next,
        confirmation: event.confirmation,
      ),
    );
  }

  Future<void> _onSubmitted(
    ChangePasswordSubmitted event,
    Emitter<ChangePasswordState> emit,
  ) async {
    if (!state.isValid) return;
    emit(state.copyWith(status: ChangePasswordStatus.saving));
    try {
      await _repository.changePassword(
        current: state.current,
        next: state.next,
      );
      emit(state.copyWith(status: ChangePasswordStatus.saved));
    } on WrongCredentialsException {
      emit(state.copyWith(status: ChangePasswordStatus.wrongCurrent));
    } on NoConnectionException {
      emit(state.copyWith(status: ChangePasswordStatus.noConnection));
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.copyWith(status: ChangePasswordStatus.failure));
    }
  }
}
