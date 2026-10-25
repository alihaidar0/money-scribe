import 'dart:convert';
import 'dart:typed_data';

import 'package:biometric_signature/biometric_signature.dart';
import 'package:money_scribe/features/auth/domain/auth_exception.dart';
import 'package:money_scribe/features/auth/domain/device_key.dart';
import 'package:money_scribe/features/auth/domain/device_key_store.dart';

/// The fingerprint sign-in key, kept by the `biometric_signature` plugin: the
/// Android Keystore (StrongBox where the phone has one) or the iOS Secure
/// Enclave. It is the only place that plugin is used.
///
/// The key is made so that the server can trust it: P-256 for signing only,
/// needing a strong biometric for every use and never the device PIN, ended
/// by a change to the enrolled fingerprints, with the server's challenge in
/// its attestation on Android.
class BiometricSignatureDeviceKeyStore implements DeviceKeyStore {
  new({
    required this._attestsKeys,
    BiometricSignature? plugin,
    this._alias = 'money_scribe.sign_in',
  }) : _plugin = plugin ?? BiometricSignature();

  final bool _attestsKeys;
  final BiometricSignature _plugin;

  /// The name of the key in the secure hardware, apart from any other key.
  final String _alias;

  @override
  Future<DeviceKeySupport> support() async {
    try {
      final availability = await _plugin.biometricAuthAvailable();
      if (availability.canAuthenticate ?? false) {
        return DeviceKeySupport.available;
      }
      return (availability.hasEnrolledBiometrics ?? true)
          ? DeviceKeySupport.unsupported
          : DeviceKeySupport.notEnrolled;
      // A platform that fails to answer has no usable biometric.
    } on Exception {
      return DeviceKeySupport.unsupported;
    }
  }

  @override
  Future<NewDeviceKey> create({required Uint8List attestationChallenge}) async {
    final result = await _plugin.createKeys(
      keyAlias: _alias,
      config: CreateKeysConfig(
        signatureType: SignatureType.ecdsa,
        // The fingerprint is asked for once, when the registration is signed.
        enforceBiometric: false,
        requireAuthentication: true,
        setInvalidatedByBiometricEnrollment: true,
        // Never the PIN or pattern of the phone.
        useDeviceCredentials: false,
        enableDecryption: false,
        // Replaces a key an earlier try left behind.
        failIfExists: false,
        attestationChallenge: _attestsKeys ? attestationChallenge : null,
      ),
      // The public key comes as base64 SPKI DER, the default format.
    );
    final publicKey = result.publicKey;
    if (result.code != BiometricError.success || publicKey == null) {
      throw _failure(result.code);
    }

    final chain = result.attestationCertificateChain;
    return NewDeviceKey(
      publicKey: publicKey,
      attestationChain: chain == null
          ? null
          : [for (final certificate in chain) base64.encode(certificate)],
    );
  }

  @override
  Future<String> sign(String text, {required String prompt}) async {
    final result = await _plugin.createSignature(
      payload: text,
      keyAlias: _alias,
      // The device PIN is not a way to sign (the default), and the signature
      // comes as base64 DER, the default format.
      promptMessage: prompt,
    );
    final signature = result.signature;
    if (result.code != BiometricError.success || signature == null) {
      final failure = _failure(result.code);
      // A key the system ended is of no use any more.
      if (failure is FingerprintKeyInvalidatedException) await delete();
      throw failure;
    }
    return signature;
  }

  @override
  Future<bool> exists() async {
    try {
      return await _plugin.biometricKeyExists(
        keyAlias: _alias,
        checkValidity: true,
      );
    } on Exception {
      return false;
    }
  }

  @override
  Future<void> delete() async {
    try {
      await _plugin.deleteKeys(keyAlias: _alias);
    } on Exception {
      // A key that cannot be deleted cannot be used either without the
      // server's public half, which is removed by the caller.
    }
  }

  /// What the plugin's error means for the person.
  AuthException _failure(BiometricError? code) {
    return switch (code) {
      BiometricError.userCanceled ||
      BiometricError.systemCanceled ||
      BiometricError.authenticationFailed ||
      BiometricError.promptError => const FingerprintCancelledException(),
      BiometricError.keyInvalidated ||
      BiometricError.keyNotFound => const FingerprintKeyInvalidatedException(),
      _ => const FingerprintUnavailableException(),
    };
  }
}
