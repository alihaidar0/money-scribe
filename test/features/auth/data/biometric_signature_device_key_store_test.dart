import 'dart:convert';
import 'dart:typed_data';

import 'package:biometric_signature/biometric_signature.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/features/auth/data/biometric_signature_device_key_store.dart';
import 'package:money_scribe/features/auth/domain/auth_exception.dart';
import 'package:money_scribe/features/auth/domain/device_key.dart';

/// The plugin, answering what a test says and remembering what it was asked.
class _Plugin extends BiometricSignature {
  BiometricAvailability availability = BiometricAvailability(
    canAuthenticate: true,
    hasEnrolledBiometrics: true,
  );
  KeyCreationResult created = KeyCreationResult(
    publicKey: 'public-key',
    code: BiometricError.success,
    attestationCertificateChain: [
      Uint8List.fromList([1, 2, 3]),
      Uint8List.fromList([251, 255]),
    ],
  );
  SignatureResult signature = SignatureResult(
    signature: 'der-signature',
    code: BiometricError.success,
  );
  KeyInfo info = KeyInfo(exists: true, isValid: true);

  CreateKeysConfig? config;
  String? createdAlias;
  String? signedPayload;
  String? signedAlias;
  String? promptMessage;
  final deleted = <String?>[];
  bool? checkedValidity;

  @override
  Future<BiometricAvailability> biometricAuthAvailable({
    BiometricStrength biometricStrength = BiometricStrength.strong,
  }) async {
    expect(biometricStrength, BiometricStrength.strong);
    return availability;
  }

  @override
  Future<KeyCreationResult> createKeys({
    String? keyAlias,
    CreateKeysConfig? config,
    KeyFormat keyFormat = KeyFormat.base64,
    String? promptMessage,
  }) async {
    createdAlias = keyAlias;
    this.config = config;
    expect(keyFormat, KeyFormat.base64);
    return created;
  }

  @override
  Future<SignatureResult> createSignature({
    required String payload,
    String? keyAlias,
    CreateSignatureConfig? config,
    SignatureFormat signatureFormat = SignatureFormat.base64,
    KeyFormat keyFormat = KeyFormat.base64,
    String? promptMessage,
  }) async {
    signedPayload = payload;
    signedAlias = keyAlias;
    this.promptMessage = promptMessage;
    expect(signatureFormat, SignatureFormat.base64);
    // The device PIN is never a way to sign.
    expect(config?.allowDeviceCredentials ?? false, isFalse);
    return signature;
  }

  @override
  Future<KeyInfo> getKeyInfo({
    String? keyAlias,
    bool checkValidity = false,
    KeyFormat keyFormat = KeyFormat.base64,
  }) async {
    checkedValidity = checkValidity;
    return info;
  }

  @override
  Future<bool> deleteKeys({String? keyAlias}) async {
    deleted.add(keyAlias);
    return true;
  }
}

void main() {
  late _Plugin platform;
  late BiometricSignatureDeviceKeyStore store;

  BiometricSignatureDeviceKeyStore build({bool attests = true}) {
    return BiometricSignatureDeviceKeyStore(
      attestsKeys: attests,
      plugin: platform,
    );
  }

  setUp(() {
    platform = _Plugin();
    store = build();
  });

  group('support', () {
    test('is available with a strong fingerprint enrolled', () async {
      expect(await store.support(), DeviceKeySupport.available);
    });

    test('says when none is enrolled', () async {
      platform.availability = BiometricAvailability(
        canAuthenticate: false,
        hasEnrolledBiometrics: false,
      );

      expect(await store.support(), DeviceKeySupport.notEnrolled);
    });

    test('says when the phone cannot do it at all', () async {
      platform.availability = BiometricAvailability(
        canAuthenticate: false,
        hasEnrolledBiometrics: true,
      );

      expect(await store.support(), DeviceKeySupport.unsupported);
    });
  });

  group('making the key', () {
    test('asks for what the server requires of it', () async {
      await store.create(attestationChallenge: Uint8List.fromList([9, 8, 7]));

      final config = platform.config!;
      expect(platform.createdAlias, 'money_scribe.sign_in');
      expect(config.signatureType, SignatureType.ecdsa);
      // A fingerprint for every use, ended by a change of fingerprints, never
      // the PIN of the phone, signing only.
      expect(config.requireAuthentication, isTrue);
      expect(config.setInvalidatedByBiometricEnrollment, isTrue);
      expect(config.useDeviceCredentials, isFalse);
      expect(config.enableDecryption, isFalse);
      expect(config.attestationChallenge, Uint8List.fromList([9, 8, 7]));
    });

    test('sends no challenge where the system cannot attest', () async {
      store = build(attests: false);

      await store.create(attestationChallenge: Uint8List.fromList([9]));

      expect(platform.config!.attestationChallenge, isNull);
    });

    test('returns the public key and the chain in base64', () async {
      final key = await store.create(
        attestationChallenge: Uint8List.fromList([1]),
      );

      expect(key.publicKey, 'public-key');
      expect(key.attestationChain, [
        base64.encode([1, 2, 3]),
        base64.encode([251, 255]),
      ]);
    });

    test('has no chain where there is no attestation', () async {
      platform.created = KeyCreationResult(
        publicKey: 'public-key',
        code: BiometricError.success,
      );

      final key = await store.create(
        attestationChallenge: Uint8List.fromList([1]),
      );

      expect(key.attestationChain, isNull);
    });

    test('a key that cannot be attested is no key', () async {
      platform.created = KeyCreationResult(code: BiometricError.notSupported);

      await expectLater(
        store.create(attestationChallenge: Uint8List.fromList([1])),
        throwsA(isA<FingerprintUnavailableException>()),
      );
    });
  });

  group('signing', () {
    test('signs the text with the key and shows the prompt', () async {
      final signature = await store.sign('text', prompt: 'Confirm');

      expect(signature, 'der-signature');
      expect(platform.signedPayload, 'text');
      expect(platform.signedAlias, 'money_scribe.sign_in');
      expect(platform.promptMessage, 'Confirm');
    });

    for (final code in [
      BiometricError.userCanceled,
      BiometricError.systemCanceled,
      BiometricError.authenticationFailed,
      BiometricError.promptError,
    ]) {
      test('$code is a cancelled check, nothing is said', () async {
        platform.signature = SignatureResult(code: code);

        await expectLater(
          store.sign('text', prompt: 'Confirm'),
          throwsA(isA<FingerprintCancelledException>()),
        );
        expect(platform.deleted, isEmpty);
      });
    }

    for (final code in [
      BiometricError.keyInvalidated,
      BiometricError.keyNotFound,
    ]) {
      test('$code ends the key and deletes it', () async {
        platform.signature = SignatureResult(code: code);

        await expectLater(
          store.sign('text', prompt: 'Confirm'),
          throwsA(isA<FingerprintKeyInvalidatedException>()),
        );
        expect(platform.deleted, ['money_scribe.sign_in']);
      });
    }

    for (final code in [
      BiometricError.lockedOut,
      BiometricError.lockedOutPermanent,
      BiometricError.notAvailable,
      BiometricError.notEnrolled,
    ]) {
      test('$code is a phone that cannot check now', () async {
        platform.signature = SignatureResult(code: code);

        await expectLater(
          store.sign('text', prompt: 'Confirm'),
          throwsA(isA<FingerprintUnavailableException>()),
        );
      });
    }
  });

  group('the key', () {
    test('exists when it is there and still valid', () async {
      expect(await store.exists(), isTrue);
      expect(platform.checkedValidity, isTrue);
    });

    test('does not exist once the system ended it', () async {
      platform.info = KeyInfo(exists: true, isValid: false);

      expect(await store.exists(), isFalse);
    });

    test('is deleted by its own name only', () async {
      await store.delete();

      expect(platform.deleted, ['money_scribe.sign_in']);
    });
  });
}
