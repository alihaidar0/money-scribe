import 'package:money_scribe/core/api/export.dart';
import 'package:money_scribe/core/device/device_info.dart';

/// The label of this device that the server keeps with a session, built from
/// what the phone says about itself.
Future<DeviceRequest> readDeviceRequest(DeviceInfoSource source) async {
  final info = await source.read();
  return DeviceRequest(
    deviceId: info.deviceId,
    deviceName: info.deviceName,
    platform: switch (info.platform) {
      DevicePlatform.android => PlatformEnum.android,
      DevicePlatform.ios => PlatformEnum.ios,
    },
    osVersion: info.osVersion,
    appVersion: info.appVersion,
  );
}
