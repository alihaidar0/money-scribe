part of 'device_key_list_bloc.dart';

sealed class DeviceKeyListEvent extends Equatable {
  const new();

  @override
  List<Object> get props => [];
}

/// The screen opened: load the phones.
final class DeviceKeyListStarted extends DeviceKeyListEvent {
  const new();
}

/// The person pressed Try again.
final class DeviceKeyListRetried extends DeviceKeyListEvent {
  const new();
}

/// The person confirmed removing the phone with [deviceId].
final class DeviceKeyRemoved extends DeviceKeyListEvent {
  const new(this.deviceId);

  final String deviceId;

  @override
  List<Object> get props => [deviceId];
}
