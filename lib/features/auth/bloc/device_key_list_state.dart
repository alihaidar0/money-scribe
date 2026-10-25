part of 'device_key_list_bloc.dart';

enum DeviceKeyListStatus {
  /// The phones are being loaded.
  loading,

  /// The phones are shown, or there are none.
  ready,

  /// The server could not be reached.
  noConnection,

  /// The server failed.
  failure,
}

/// Why removing a phone did not happen.
enum DeviceKeyListFailure {
  /// The server could not be reached.
  offline,

  /// The server is busy.
  busy,

  /// Anything else.
  other,
}

final class DeviceKeyListState extends Equatable {
  const new({
    this.status = DeviceKeyListStatus.loading,
    this.keys = const [],
    this.removingId,
    this.removedCount = 0,
    this.failedAction,
    this.failure,
  });

  final DeviceKeyListStatus status;

  /// The phones that can sign the account in, the newest first.
  final List<DeviceKeyEntry> keys;

  /// The device id of the phone being removed, if one is.
  final String? removingId;

  /// How many phones were removed since the screen opened, so the screen can
  /// say so once for each.
  final int removedCount;

  /// The removal the server did not accept, so the screen can offer to try it
  /// again. `null` once something else was done.
  final DeviceKeyRemoved? failedAction;

  /// Why [failedAction] failed.
  final DeviceKeyListFailure? failure;

  DeviceKeyListState copyWith({
    DeviceKeyListStatus? status,
    List<DeviceKeyEntry>? keys,
    String? removingId,
    bool clearRemovingId = false,
    int? removedCount,
    DeviceKeyRemoved? failedAction,
    DeviceKeyListFailure? failure,
    bool clearFailure = false,
  }) {
    return DeviceKeyListState(
      status: status ?? this.status,
      keys: keys ?? this.keys,
      removingId: clearRemovingId ? null : removingId ?? this.removingId,
      removedCount: removedCount ?? this.removedCount,
      failedAction: clearFailure ? null : failedAction ?? this.failedAction,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }

  @override
  List<Object?> get props => [
    status,
    keys,
    removingId,
    removedCount,
    failedAction,
    failure,
  ];
}
