part of 'register_bloc.dart';

sealed class RegisterEvent extends Equatable {
  const new();
}

/// The user pressed Create account.
final class RegisterSubmitted extends RegisterEvent {
  const new({required this.name, required this.email, required this.password});

  final String name;
  final String email;
  final String password;

  @override
  List<Object> get props => [name, email, password];
}
