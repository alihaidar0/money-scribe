import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:money_scribe/features/auth/domain/device_key.dart';

/// A key pair that was just made, as the server needs to know it.
final class NewDeviceKey extends Equatable {
  const new({required this.publicKey, this.attestationChain});

  /// The public half: P-256, SPKI DER, standard base64 with padding.
  final String publicKey;

  /// Android only: the certificate chain that vouches for the key, leaf first,
  /// each certificate DER in standard base64. `null` where the system has no
  /// key attestation (iOS).
  final List<String>? attestationChain;

  @override
  List<Object?> get props => [publicKey, attestationChain];
}

/// The key pair of this phone that signs the fingerprint sign-in, kept in the
/// secure hardware. The private half never leaves it, and every signature
/// needs a fingerprint; adding or removing a fingerprint on the phone ends
/// the key. An interface, so tests keep the keys in memory.
///
/// Every failure is an `AuthException`: `FingerprintCancelledException`,
/// `FingerprintUnavailableException` or `FingerprintKeyInvalidatedException`.
abstract interface class DeviceKeyStore {
  /// Whether the phone can hold the key, without asking for a fingerprint.
  Future<DeviceKeySupport> support();

  /// Makes a new key pair, replacing the one the phone had, and returns the
  /// public half. [attestationChallenge] is the server's 32 raw bytes, which
  /// the system embeds in the certificate chain where it can.
  Future<NewDeviceKey> create({required Uint8List attestationChallenge});

  /// Signs [text] (UTF-8) with the key after the system checked a fingerprint,
  /// showing [prompt], and returns the signature: ECDSA on P-256 with SHA-256,
  /// DER, standard base64.
  Future<String> sign(String text, {required String prompt});

  /// Whether a key exists that has not been invalidated.
  Future<bool> exists();

  /// Deletes the key. Does nothing when there is none.
  Future<void> delete();
}
