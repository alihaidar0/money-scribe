import 'dart:math';

final _uuid = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

/// A random version 4 UUID, such as `0b9f2a8e-5c1d-4e7a-9a43-2f6d8c1e7b10`,
/// from a secure random source unless [random] is given.
String randomUuidV4([Random? random]) {
  final source = random ?? Random.secure();
  final bytes = List<int>.generate(16, (_) => source.nextInt(256));
  // Version 4 and the RFC 4122 variant.
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;

  String hex(int from, int to) {
    return [
      for (var index = from; index < to; index++)
        bytes[index].toRadixString(16).padLeft(2, '0'),
    ].join();
  }

  return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
}

/// Whether [value] is a version 4 UUID in lower case.
bool isUuidV4(String value) => _uuid.hasMatch(value);
