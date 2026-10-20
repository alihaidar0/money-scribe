import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/time/duration_seconds.dart';
import 'package:money_scribe/core/time/ticker.dart';
import 'package:money_scribe/features/auth/domain/auth_exception.dart';
import 'package:money_scribe/features/auth/domain/auth_repository.dart';

part 'code_verification_event.dart';
part 'code_verification_state.dart';

/// The screens that ask for the 6-digit code sent by email: verifying a new
/// account and resetting a password. The purpose tells them apart. Every wait
/// comes from the server through the repository, never from a constant here.
class CodeVerificationBloc
    extends Bloc<CodeVerificationEvent, CodeVerificationState> {
  new({
    required this._purpose,
    required this._repository,
    required this._ticker,
  }) : super(
         CodeVerificationState(
           email: _repository.pendingEmail ?? '',
           resendSecondsLeft: _repository.resendWaitRemaining.ceilSeconds,
         ),
       ) {
    on<CodeVerificationStarted>(_onStarted, transformer: droppable());
    on<CodeEdited>(_onEdited, transformer: sequential());
    // A second code is not sent while the first is being checked.
    on<CodeSubmitted>(_onSubmitted, transformer: droppable());
    on<CodeResendRequested>(_onResendRequested, transformer: droppable());
    on<_CodeResendTicked>(_onResendTicked, transformer: sequential());
    on<_CodeWaitTicked>(_onWaitTicked, transformer: sequential());
  }

  /// How many digits a code has.
  static const codeLength = 6;

  final CodePurpose _purpose;
  final AuthRepository _repository;
  final Ticker _ticker;
  StreamSubscription<int>? _resendTimer;
  StreamSubscription<int>? _waitTimer;

  void _onStarted(
    CodeVerificationStarted event,
    Emitter<CodeVerificationState> emit,
  ) {
    _startResendTimer(state.resendSecondsLeft);
  }

  void _onEdited(CodeEdited event, Emitter<CodeVerificationState> emit) {
    // Typing again clears an error; an expired or dead code stays so until a
    // new one is sent.
    final clears = switch (state.status) {
      CodeVerificationStatus.wrong ||
      CodeVerificationStatus.noConnection ||
      CodeVerificationStatus.unavailable ||
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
    final blocked = switch (state.status) {
      CodeVerificationStatus.expired ||
      CodeVerificationStatus.attemptsExceeded ||
      CodeVerificationStatus.rateLimited => true,
      _ => false,
    };
    if (blocked) return;

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
    } on RateLimitedException catch (error) {
      final seconds = error.retryAfter.ceilSeconds;
      if (error.reason == RateLimitReason.codeAttemptsExceeded) {
        // The code is dead; the wait is the time until a new one may be asked
        // for.
        emit(
          state.copyWith(
            status: CodeVerificationStatus.attemptsExceeded,
            resendSecondsLeft: seconds,
          ),
        );
        _startResendTimer(seconds);
      } else {
        emit(
          state.copyWith(
            status: CodeVerificationStatus.rateLimited,
            waitSecondsLeft: seconds,
          ),
        );
        _startWaitTimer(seconds);
      }
    } on ServiceUnavailableException {
      emit(state.copyWith(status: CodeVerificationStatus.unavailable));
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
    // The server decides when a new code may be asked for.
    if (state.resendSecondsLeft > 0) return;
    try {
      await _repository.resendCode(_purpose);
      final seconds = _repository.resendWaitRemaining.ceilSeconds;
      emit(
        state.copyWith(
          status: CodeVerificationStatus.entering,
          resendSecondsLeft: seconds,
          attemptsLeft: null,
        ),
      );
      _startResendTimer(seconds);
    } on RateLimitedException catch (error) {
      // Too soon, too many codes this hour, or too many requests: the button
      // counts down until the server allows it.
      final seconds = error.retryAfter.ceilSeconds;
      emit(state.copyWith(resendSecondsLeft: seconds));
      _startResendTimer(seconds);
    } on ServiceUnavailableException {
      emit(state.copyWith(status: CodeVerificationStatus.unavailable));
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

  void _onWaitTicked(
    _CodeWaitTicked event,
    Emitter<CodeVerificationState> emit,
  ) {
    if (state.status != CodeVerificationStatus.rateLimited) return;
    emit(
      event.secondsLeft > 0
          ? state.copyWith(waitSecondsLeft: event.secondsLeft)
          : state.copyWith(
              status: CodeVerificationStatus.entering,
              waitSecondsLeft: 0,
            ),
    );
  }

  void _startResendTimer(int seconds) {
    unawaited(_resendTimer?.cancel());
    if (seconds <= 0) return;
    _resendTimer = _ticker
        .countdown(seconds)
        .listen((left) => add(_CodeResendTicked(left)));
  }

  void _startWaitTimer(int seconds) {
    unawaited(_waitTimer?.cancel());
    if (seconds <= 0) return;
    _waitTimer = _ticker
        .countdown(seconds)
        .listen((left) => add(_CodeWaitTicked(left)));
  }

  @override
  Future<void> close() async {
    await _resendTimer?.cancel();
    await _waitTimer?.cancel();
    await super.close();
  }
}
