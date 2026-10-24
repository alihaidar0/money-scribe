part of 'app_lock_setting_bloc.dart';

final class AppLockSettingState extends Equatable {
  const new({
    this.isEnabled = false,
    this.isBusy = false,
    this.timeout = LockTimeout.standard,
    this.biometricsAvailable = false,
    this.biometricsEnabled = false,
    this.biometricsRefused = false,
    this.pinNeeded = false,
  });

  /// Whether the app lock is on.
  final bool isEnabled;

  /// Whether the answer of the device is awaited.
  final bool isBusy;

  /// How long the app may stay in the background before it locks.
  final LockTimeout timeout;

  /// Whether the device has a fingerprint (or face) the person enrolled.
  final bool biometricsAvailable;

  /// Whether the person turned the fingerprint on.
  final bool biometricsEnabled;

  /// The fingerprint that was asked for to turn it on did not match, so it
  /// stayed off. Only the attempt that failed sees it as `true`.
  final bool biometricsRefused;

  /// The fingerprint matched but there is no PIN yet: the Create a PIN screen
  /// has to open, and the fingerprint is turned on once the PIN is saved. Only
  /// the attempt that needs it sees it as `true`.
  final bool pinNeeded;

  AppLockSettingState copyWith({
    bool? isBusy,
    LockTimeout? timeout,
    bool? biometricsEnabled,
    bool? biometricsRefused,
    bool? pinNeeded,
  }) {
    return AppLockSettingState(
      isEnabled: isEnabled,
      isBusy: isBusy ?? this.isBusy,
      timeout: timeout ?? this.timeout,
      biometricsAvailable: biometricsAvailable,
      biometricsEnabled: biometricsEnabled ?? this.biometricsEnabled,
      biometricsRefused: biometricsRefused ?? false,
      pinNeeded: pinNeeded ?? false,
    );
  }

  @override
  List<Object> get props => [
    isEnabled,
    isBusy,
    timeout,
    biometricsAvailable,
    biometricsEnabled,
    biometricsRefused,
    pinNeeded,
  ];
}
