import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/features/auth/domain/auth_exception.dart';
import 'package:money_scribe/features/auth/domain/auth_repository.dart';

part 'register_event.dart';
part 'register_state.dart';

/// The Create account screen: sends the new account and shows what the server
/// refused.
class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  new({required this._repository}) : super(const RegisterState()) {
    // A second press while the first is being sent is ignored.
    on<RegisterSubmitted>(_onSubmitted, transformer: droppable());
  }

  final AuthRepository _repository;

  Future<void> _onSubmitted(
    RegisterSubmitted event,
    Emitter<RegisterState> emit,
  ) async {
    emit(const RegisterState(status: RegisterStatus.submitting));
    try {
      await _repository.register(
        name: event.name,
        email: event.email,
        password: event.password,
      );
      emit(const RegisterState(status: RegisterStatus.success));
    } on RegistrationRejectedException catch (error) {
      emit(
        RegisterState(
          status: RegisterStatus.rejected,
          problems: error.problems,
        ),
      );
    } on NoConnectionException {
      emit(const RegisterState(status: RegisterStatus.noConnection));
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(const RegisterState(status: RegisterStatus.failure));
    }
  }
}
