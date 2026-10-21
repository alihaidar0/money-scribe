import 'package:money_scribe/core/storage/secure_value_store.dart';

/// Secure storage that keeps its values in memory.
class InMemorySecureValueStore implements SecureValueStore {
  new([Map<String, String>? values]) : values = values ?? {};

  final Map<String, String> values;

  /// Every write, in order, as `key`.
  final writes = <String>[];

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    writes.add(key);
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async => values.remove(key);
}
