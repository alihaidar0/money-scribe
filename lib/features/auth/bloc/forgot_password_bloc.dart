import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/features/auth/domain/auth_repository.dart';

part 'forgot_password_event.dart';
part 'forgot_password_state.dart';

/// The Forgot password screen: asks the server to send a code to the email.
class ForgotPasswordBloc
    extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  new({required this._repository}) : super(const ForgotPasswordState()) {
    // A second press while the first is being sent is ignored.
    on<ForgotPasswordSubmitted>(_onSubmitted, transformer: droppable());
  }

  final AuthRepository _repository;

  Future<void> _onSubmitted(
    ForgotPasswordSubmitted event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    emit(const ForgotPasswordState(status: ForgotPasswordStatus.submitting));
    try {
      await _repository.requestPasswordReset(event.email);
      emit(const ForgotPasswordState(status: ForgotPasswordStatus.success));
    } on FeatureNotAvailableException {
      emit(
        const ForgotPasswordState(status: ForgotPasswordStatus.notAvailable),
      );
    } on NoConnectionException {
      emit(
        const ForgotPasswordState(status: ForgotPasswordStatus.noConnection),
      );
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(const ForgotPasswordState(status: ForgotPasswordStatus.failure));
    }
  }
}
