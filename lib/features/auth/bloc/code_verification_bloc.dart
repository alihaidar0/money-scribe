import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/time/ticker.dart';
import 'package:money_scribe/features/auth/domain/auth_exception.dart';
import 'package:money_scribe/features/auth/domain/auth_repository.dart';

part 'code_verification_event.dart';
part 'code_verification_state.dart';

/// The screens that ask for the 4-digit code sent by email: verifying a new
/// account and resetting a password. The purpose tells them apart.
class CodeVerificationBloc
    extends Bloc<CodeVerificationEvent, CodeVerificationState> {
  new({
    required this._purpose,
    required this._repository,
    required this._ticker,
  }) : super(
         CodeVerificationState(
           email: _repository.pendingEmail ?? '',
           resendSecondsLeft: resendDelaySeconds,
         ),
       ) {
    on<CodeVerificationStarted>(_onStarted, transformer: droppable());
    on<CodeEdited>(_onEdited, transformer: sequential());
    // A second code is not sent while the first is being checked.
    on<CodeSubmitted>(_onSubmitted, transformer: droppable());
    on<CodeResendRequested>(_onResendRequested, transformer: droppable());
    on<_CodeResendTicked>(_onResendTicked, transformer: sequential());
  }

  /// How long a new code cannot be asked for.
  static const resendDelaySeconds = 60;

  /// How many digits a code has.
  static const codeLength = 4;

  final CodePurpose _purpose;
  final AuthRepository _repository;
  final Ticker _ticker;
  StreamSubscription<int>? _resendTimer;

  void _onStarted(
    CodeVerificationStarted event,
    Emitter<CodeVerificationState> emit,
  ) {
    _startResendTimer();
  }

  void _onEdited(CodeEdited event, Emitter<CodeVerificationState> emit) {
    // Typing again clears an error; an expired code stays expired until a new
    // one is sent.
    final clears = switch (state.status) {
      CodeVerificationStatus.wrong ||
      CodeVerificationStatus.noConnection ||
      CodeVerificationStatus.failure => true,
      _ => false,
    };
    if (clears) emit(state.copyWith(status: CodeVerificationStatus.entering));
  }

  Future<void> _onSubmitted(
    CodeSubmitted event,
    Emitter<CodeVerificationState> emit,
  ) async {
    if (event.code.length != codeLength) return;
    if (state.status == CodeVerificationStatus.expired) return;
    emit(state.copyWith(status: CodeVerificationStatus.verifying));
    try {
      await _repository.verifyCode(_purpose, event.code);
      emit(state.copyWith(status: CodeVerificationStatus.verified));
    } on WrongCodeException catch (error) {
      emit(
        state.copyWith(
          status: CodeVerificationStatus.wrong,
          attemptsLeft: error.attemptsLeft,
        ),
      );
    } on CodeExpiredException {
      emit(state.copyWith(status: CodeVerificationStatus.expired));
    } on NoConnectionException {
      emit(state.copyWith(status: CodeVerificationStatus.noConnection));
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.copyWith(status: CodeVerificationStatus.failure));
    }
  }

  Future<void> _onResendRequested(
    CodeResendRequested event,
    Emitter<CodeVerificationState> emit,
  ) async {
    final canResend =
        state.resendSecondsLeft == 0 ||
        state.status == CodeVerificationStatus.expired;
    if (!canResend) return;
    try {
      await _repository.resendCode(_purpose);
      emit(
        state.copyWith(
          status: CodeVerificationStatus.entering,
          resendSecondsLeft: resendDelaySeconds,
        ),
      );
      _startResendTimer();
    } on NoConnectionException {
      emit(state.copyWith(status: CodeVerificationStatus.noConnection));
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.copyWith(status: CodeVerificationStatus.failure));
    }
  }

  void _onResendTicked(
    _CodeResendTicked event,
    Emitter<CodeVerificationState> emit,
  ) {
    emit(state.copyWith(resendSecondsLeft: event.secondsLeft));
  }

  void _startResendTimer() {
    unawaited(_resendTimer?.cancel());
    _resendTimer = _ticker
        .countdown(resendDelaySeconds)
        .listen((left) => add(_CodeResendTicked(left)));
  }

  @override
  Future<void> close() async {
    await _resendTimer?.cancel();
    await super.close();
  }
}
