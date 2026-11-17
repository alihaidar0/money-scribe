import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keeps small secret values in the platform's secure storage (the Android
/// Keystore, the iOS Keychain): session tokens and the device id. Never for
/// settings, which go in `shared_preferences`.
///
/// An interface, so tests keep the values in memory.
abstract interface class SecureValueStore {
  /// The value kept under [key], or `null` when there is none, or when it can
  /// no longer be read (for example after a restore onto another device).
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}

/// The secure storage the app uses.
///
/// An iOS Keychain item is kept only while the phone is unlocked and only on
/// this phone: the plugin's default lets it travel in an encrypted backup to
/// another phone, and a session token that travelled would still be signed in
/// there. (iOS has no release yet, so no earlier item needs to be moved.)
const deviceOnlySecureStorage = FlutterSecureStorage(
  iOptions: IOSOptions(
    accessibility: KeychainAccessibility.unlocked_this_device,
  ),
);

/// The real secure storage.
class PlatformSecureValueStore implements SecureValueStore {
  const new([this._storage = deviceOnlySecureStorage]);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } on Exception {
      // A value that cannot be decrypted is as good as lost: the person signs
      // in again, and a new value replaces it.
      return null;
    }
  }

  @override
  Future<void> write(String key, String value) {
    return _storage.write(key: key, value: value);
  }

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}
