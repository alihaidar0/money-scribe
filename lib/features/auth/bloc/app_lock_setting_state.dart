part of 'app_lock_setting_bloc.dart';

final class AppLockSettingState extends Equatable {
  const new({
    this.isEnabled = false,
    this.isBusy = false,
    this.timeout = LockTimeout.standard,
  });

  /// Whether the app lock is on.
  final bool isEnabled;

  /// Whether the answer of the device is awaited.
  final bool isBusy;

  /// How long the app may stay in the background before it locks.
  final LockTimeout timeout;

  AppLockSettingState copyWith({bool? isBusy, LockTimeout? timeout}) {
    return AppLockSettingState(
      isEnabled: isEnabled,
      isBusy: isBusy ?? this.isBusy,
      timeout: timeout ?? this.timeout,
    );
  }

  @override
  List<Object> get props => [isEnabled, isBusy, timeout];
}
