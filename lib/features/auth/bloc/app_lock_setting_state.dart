part of 'app_lock_setting_bloc.dart';

final class AppLockSettingState extends Equatable {
  const new({this.isEnabled = false, this.isBusy = false});

  /// Whether the app lock is on.
  final bool isEnabled;

  /// Whether the answer of the device is awaited.
  final bool isBusy;

  @override
  List<Object> get props => [isEnabled, isBusy];
}
