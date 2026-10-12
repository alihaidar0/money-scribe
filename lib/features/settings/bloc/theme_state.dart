part of 'theme_bloc.dart';

final class ThemeState extends Equatable {
  const new(this.choice);

  final ThemeChoice choice;

  @override
  List<Object> get props => [choice];
}
