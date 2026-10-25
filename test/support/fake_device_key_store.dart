import 'dart:typed_data';

import 'package:money_scribe/features/auth/domain/device_key.dart';
import 'package:money_scribe/features/auth/domain/device_key_store.dart';

/// The fingerprint sign-in key of the phone, kept in memory. A test sets what
/// the phone can do and how a fingerprint check ends, and reads what was asked
/// of the key.
class FakeDeviceKeyStore implements DeviceKeyStore {
  new({this.supportValue = DeviceKeySupport.available});

  DeviceKeySupport supportValue;

  /// Whether a key is held now.
  bool hasKey = false;

  /// Thrown by [create] and by [sign] when set (an `AuthException`).
  Exception? createFailure;
  Exception? signFailure;

  /// Whether a created key comes with an attestation chain, as on Android.
  bool attests = true;

  /// The challenge each key was made with, and each text signed, in order.
  final challenges = <Uint8List>[];
  final signed = <String>[];
  final prompts = <String>[];

  int deletions = 0;

  @override
  Future<DeviceKeySupport> support() async => supportValue;

  @override
  Future<NewDeviceKey> create({required Uint8List attestationChallenge}) async {
    final failure = createFailure;
    if (failure != null) throw failure;
    challenges.add(attestationChallenge);
    hasKey = true;
    return NewDeviceKey(
      publicKey: 'public-key-${challenges.length}',
      attestationChain: attests
          ? const ['certificate-1', 'certificate-2']
          : null,
    );
  }

  @override
  Future<String> sign(String text, {required String prompt}) async {
    final failure = signFailure;
    if (failure != null) {
      // Like the real key, one the system ended is gone.
      hasKey = false;
      throw failure;
    }
    signed.add(text);
    prompts.add(prompt);
    return 'signature-${signed.length}';
  }

  @override
  Future<bool> exists() async => hasKey;

  @override
  Future<void> delete() async {
    deletions++;
    hasKey = false;
  }
}
