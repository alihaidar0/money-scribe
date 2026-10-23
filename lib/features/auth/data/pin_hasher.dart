import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// A salted hash of a PIN, in the form it is kept in: the version of the
/// scheme, the salt, the number of rounds and the hash.
final class PinVerifier {
  const new({required this.salt, required this.hash, required this.iterations});

  /// Reads what [toJson] wrote, or `null` for anything else.
  static PinVerifier? tryParse(String? text) {
    if (text == null) return null;
    try {
      final json = jsonDecode(text);
      if (json is! Map<String, dynamic> || json['v'] != 1) return null;
      final salt = json['salt'];
      final hash = json['hash'];
      final iterations = json['iter'];
      if (salt is! String || hash is! String || iterations is! int) {
        return null;
      }
      return PinVerifier(salt: salt, hash: hash, iterations: iterations);
    } on FormatException {
      return null;
    }
  }

  /// Base64 of the random salt.
  final String salt;

  /// Base64 of the derived key.
  final String hash;

  final int iterations;

  String toJson() {
    return jsonEncode({'v': 1, 'salt': salt, 'hash': hash, 'iter': iterations});
  }
}

/// Hashes a PIN with PBKDF2-HMAC-SHA256 and a random salt. The work runs in an
/// isolate, so the screen keeps moving while it counts.
///
/// The hash is a second line of defence: a 4-digit PIN can always be guessed
/// offline, so what protects it is the secure storage that holds the hash and
/// the limit on tries (`PinLockoutPolicy`).
class PinHasher {
  const new({this.iterations = defaultIterations, this.useIsolate = true});

  /// About a tenth of a second on a desktop, a few times that on a phone.
  static const defaultIterations = 50000;

  final int iterations;

  /// Off in tests, which run without isolates.
  final bool useIsolate;

  /// A new salted hash of [pin].
  Future<PinVerifier> create(String pin) async {
    final random = Random.secure();
    final salt = Uint8List.fromList(
      List<int>.generate(16, (_) => random.nextInt(256)),
    );
    final hash = await _derive(pin, salt, iterations);
    return PinVerifier(
      salt: base64Encode(salt),
      hash: base64Encode(hash),
      iterations: iterations,
    );
  }

  /// Whether [pin] gives [verifier]. The comparison takes the same time
  /// wherever the two differ.
  Future<bool> matches(String pin, PinVerifier verifier) async {
    final Uint8List salt;
    final Uint8List expected;
    try {
      salt = base64Decode(verifier.salt);
      expected = base64Decode(verifier.hash);
    } on FormatException {
      return false;
    }
    final actual = await _derive(pin, salt, verifier.iterations);
    return _sameBytes(actual, expected);
  }

  Future<Uint8List> _derive(String pin, Uint8List salt, int rounds) {
    return useIsolate
        ? Isolate.run(() => pbkdf2(utf8.encode(pin), salt, rounds))
        : Future.value(pbkdf2(utf8.encode(pin), salt, rounds));
  }

  /// PBKDF2 with HMAC-SHA256 and one 32-byte block (RFC 8018).
  static Uint8List pbkdf2(List<int> password, List<int> salt, int iterations) {
    final hmac = Hmac(sha256, password);
    final first = Uint8List(salt.length + 4)
      ..setRange(0, salt.length, salt)
      // The block number, 1, as four bytes.
      ..[salt.length + 3] = 1;
    var current = hmac.convert(first).bytes;
    final result = Uint8List.fromList(current);
    for (var round = 1; round < iterations; round++) {
      current = hmac.convert(current).bytes;
      for (var i = 0; i < result.length; i++) {
        result[i] ^= current[i];
      }
    }
    return result;
  }

  static bool _sameBytes(Uint8List a, Uint8List b) {
    var difference = a.length ^ b.length;
    for (var i = 0; i < a.length && i < b.length; i++) {
      difference |= a[i] ^ b[i];
    }
    return difference == 0;
  }
}
