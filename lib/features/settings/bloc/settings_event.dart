part of 'settings_bloc.dart';

sealed class SettingsEvent extends Equatable {
  const new();

  @override
  List<Object> get props => [];
}

/// The Settings screen opened: load the pay schedule and the currency.
final class SettingsStarted extends SettingsEvent {
  const new();
}

/// The user pressed Try again.
final class SettingsRetried extends SettingsEvent {
  const new();
}

/// The user came back from a screen that may have changed the pay schedule:
/// load it again without the loading state.
final class SettingsRefreshed extends SettingsEvent {
  const new();
}

/// The user chose a default currency.
final class DefaultCurrencySelected extends SettingsEvent {
  const new(this.currency);

  final Currency currency;

  @override
  List<Object> get props => [currency];
}

/// The user turned the reminder on the pay days on or off.
final class PayDayReminderToggled extends SettingsEvent {
  const new({required this.remind});

  final bool remind;

  @override
  List<Object> get props => [remind];
}
