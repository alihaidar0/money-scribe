import 'dart:math';

/// Makes a random version 4 UUID (RFC 9562), such as
/// `0b9f2a8e-5c1d-4e7a-9a43-2f6d8c1e7b10`.
///
/// It uses a secure random source by default, so the ids it makes cannot be
/// guessed; tests pass a seeded [Random].
String generateUuidV4([Random? random]) {
  final source = random ?? Random.secure();
  final bytes = List<int>.generate(16, (_) => source.nextInt(256));
  // The version (4) and the variant (10xx) are fixed bits of the format.
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;

  final hex = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0'));
  final text = hex.join();
  return '${text.substring(0, 8)}-${text.substring(8, 12)}-'
      '${text.substring(12, 16)}-${text.substring(16, 20)}-'
      '${text.substring(20)}';
}
