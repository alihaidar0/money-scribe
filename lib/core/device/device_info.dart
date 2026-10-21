import 'package:equatable/equatable.dart';

/// The platforms the app signs in from. The web has no session on the device
/// until the server's cookie flow exists, so it is not here.
enum DevicePlatform { android, ios }

/// How the server labels a device in the sessions of an account. Nothing
/// personal: the model name is the maker's, never the name the person gave the
/// device.
final class DeviceInfo extends Equatable {
  const new({
    required this.deviceId,
    required this.deviceName,
    required this.platform,
    required this.osVersion,
    required this.appVersion,
  });

  /// A random UUID made once at install and kept in the secure storage.
  final String deviceId;

  /// The model, such as `Pixel 8`; at most 100 characters.
  final String deviceName;

  final DevicePlatform platform;

  /// The version of the system, such as `14`; at most 50 characters, empty
  /// when unknown.
  final String osVersion;

  /// The app's version and build, such as `1.0.0+1`; at most 50 characters.
  final String appVersion;

  @override
  List<Object> get props => [
    deviceId,
    deviceName,
    platform,
    osVersion,
    appVersion,
  ];
}

/// Where the device's description comes from. An interface, so a test gives
/// its own.
abstract interface class DeviceInfoSource {
  Future<DeviceInfo> read();
}
