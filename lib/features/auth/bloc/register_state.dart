part of 'register_bloc.dart';

enum RegisterStatus {
  /// Waiting for the form.
  idle,

  /// The account is being created.
  submitting,

  /// The account exists and a code was sent.
  success,

  /// The server refused some of the data: see [RegisterState.problems].
  rejected,

  /// The server could not be reached.
  noConnection,

  /// The server failed.
  failure,
}

final class RegisterState extends Equatable {
  const new({
    this.status = RegisterStatus.idle,
    this.problems = const <RegistrationProblem>{},
  });

  final RegisterStatus status;

  /// What was wrong, while [status] is `rejected`.
  final Set<RegistrationProblem> problems;

  @override
  List<Object> get props => [status, problems];
}
