part of 'language_bloc.dart';

/// The language of the app.
final class LanguageState extends Equatable {
  const new(this.language);

  final AppLanguage language;

  @override
  List<Object> get props => [language];
}
