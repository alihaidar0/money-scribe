import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:money_scribe/core/device/device_info.dart';
import 'package:money_scribe/core/device/random_uuid.dart';
import 'package:money_scribe/core/storage/secure_value_store.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Describes this device from the platform: the id kept in the secure storage,
/// the model, the system version and the app's version.
class PlatformDeviceInfoSource implements DeviceInfoSource {
  new(this._store, [DeviceInfoPlugin? plugin])
    : _plugin = plugin ?? DeviceInfoPlugin();

  static const _idKey = 'device_id';

  /// The limits of the server's `device` object.
  static const maxNameLength = 100;
  static const maxVersionLength = 50;

  final SecureValueStore _store;
  final DeviceInfoPlugin _plugin;

  DeviceInfo? _cached;

  @override
  Future<DeviceInfo> read() async {
    final cached = _cached;
    if (cached != null) return cached;

    final String name;
    final String os;
    final DevicePlatform platform;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final info = await _plugin.androidInfo;
        platform = DevicePlatform.android;
        name = info.model;
        os = info.version.release;
      case TargetPlatform.iOS:
        final info = await _plugin.iosInfo;
        platform = DevicePlatform.ios;
        name = info.modelName;
        os = info.systemVersion;
      case _:
        throw UnsupportedError('Only Android and iOS sign in from a device.');
    }

    final package = await PackageInfo.fromPlatform();
    final build = package.buildNumber.isEmpty ? '' : '+${package.buildNumber}';

    return _cached = DeviceInfo(
      deviceId: await _deviceId(),
      deviceName: clip(
        name.trim().isEmpty ? _fallbackName(platform) : name.trim(),
        maxNameLength,
      ),
      platform: platform,
      osVersion: clip(os.trim(), maxVersionLength),
      appVersion: clip('${package.version}$build', maxVersionLength),
    );
  }

  /// The id of this install: made once, then read back. A stored value that
  /// is not a UUID is replaced.
  Future<String> _deviceId() async {
    final stored = await _store.read(_idKey);
    if (stored != null && isUuidV4(stored)) return stored;
    final created = randomUuidV4();
    await _store.write(_idKey, created);
    return created;
  }

  static String _fallbackName(DevicePlatform platform) {
    return switch (platform) {
      DevicePlatform.android => 'Android device',
      DevicePlatform.ios => 'iPhone',
    };
  }

  /// The first [max] characters of [text], for the server's length limits.
  static String clip(String text, int max) {
    return text.length <= max ? text : text.substring(0, max);
  }
}
