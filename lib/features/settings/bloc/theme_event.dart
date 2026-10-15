part of 'theme_bloc.dart';

sealed class ThemeEvent extends Equatable {
  const new();
}

/// The user chose a theme.
final class ThemeSelected extends ThemeEvent {
  const new(this.choice);

  final ThemeChoice choice;

  @override
  List<Object> get props => [choice];
}
