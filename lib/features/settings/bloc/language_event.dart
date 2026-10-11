part of 'language_bloc.dart';

sealed class LanguageEvent extends Equatable {
  const new();
}

/// The user chose a language on the Settings screen.
final class LanguageSelected extends LanguageEvent {
  const new(this.language);

  final AppLanguage language;

  @override
  List<Object> get props => [language];
}
