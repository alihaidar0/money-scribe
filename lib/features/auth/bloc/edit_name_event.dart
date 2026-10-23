part of 'edit_name_bloc.dart';

sealed class EditNameEvent extends Equatable {
  const new();
}

/// The user changed the name in the field.
final class EditNameChanged extends EditNameEvent {
  const new(this.name);

  final String name;

  @override
  List<Object> get props => [name];
}

/// The user pressed Save.
final class EditNameSubmitted extends EditNameEvent {
  const new();

  @override
  List<Object> get props => [];
}
