part of 'device_key_setting_bloc.dart';

sealed class DeviceKeySettingEvent extends Equatable {
  const new();

  @override
  List<Object> get props => [];
}

/// The row appeared: ask what the phone can do and whether the sign-in is on.
final class DeviceKeySettingRefreshed extends DeviceKeySettingEvent {
  const new();
}

/// The person typed their password to turn the sign-in on. [prompt] is what
/// the system's fingerprint dialog says. The password is only passed on to the
/// server and never kept.
final class FingerprintSignInTurnedOn extends DeviceKeySettingEvent {
  const new({required this.password, required this.prompt});

  final String password;
  final String prompt;

  @override
  List<Object> get props => [password, prompt];
}

/// The person turned the sign-in off.
final class FingerprintSignInTurnedOff extends DeviceKeySettingEvent {
  const new();
}
