import 'dart:convert';
import 'dart:typed_data';

import 'package:money_scribe/core/api/export.dart';
import 'package:money_scribe/core/device/device_info.dart';
import 'package:money_scribe/core/device/time_zone_source.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/network/call_api.dart';
import 'package:money_scribe/core/storage/secure_value_store.dart';
import 'package:money_scribe/features/auth/data/remote/device_request.dart';
import 'package:money_scribe/features/auth/data/remote/remote_auth_errors.dart';
import 'package:money_scribe/features/auth/domain/auth_exception.dart';
import 'package:money_scribe/features/auth/domain/auth_repository.dart';
import 'package:money_scribe/features/auth/domain/device_key.dart';
import 'package:money_scribe/features/auth/domain/device_key_repository.dart';
import 'package:money_scribe/features/auth/domain/device_key_store.dart';
import 'package:money_scribe/features/auth/domain/device_key_texts.dart';

/// Fingerprint sign-in on the server: the real [DeviceKeyRepository].
///
/// The private key never leaves the secure hardware of the phone ([_store]);
/// the server keeps the public half. Next to the key the phone keeps the name
/// and a masked address of the account it belongs to, in the secure storage,
/// so the sign-in screen can say whom the fingerprint signs in while nobody is
/// signed in.
class RemoteDeviceKeyRepository implements DeviceKeyRepository {
  new({
    required this._plain,
    required this._authenticated,
    required this._store,
    required this._secure,
    required this._device,
    required this._timeZone,
    required this._language,
    required this._auth,
    required this._startSession,
  });

  static const _accountKey = 'device_key.account';

  /// The client that sends no token: the challenge and the sign-in.
  final AuthClient _plain;

  /// The client that sends the token and renews it: registering, listing and
  /// removing keys.
  final AuthClient _authenticated;

  final DeviceKeyStore _store;
  final SecureValueStore _secure;
  final DeviceInfoSource _device;
  final TimeZoneSource _timeZone;

  /// The language of the app now: `en` or `ar`.
  final String Function() _language;

  final AuthRepository _auth;

  /// Starts the session of a sign-in made with the key.
  final Future<void> Function(SignedInResponse answer) _startSession;

  @override
  Future<DeviceKeySupport> support() => _store.support();

  @override
  Future<bool> isEnabled() async {
    final label = await _readLabel();
    if (label == null) return false;
    final accountId = _auth.accountId;
    if (accountId != null && label.accountId != accountId) return false;
    return await _store.exists();
  }

  @override
  Future<void> enable({
    required String password,
    required String prompt,
  }) async {
    if (await _store.support() != DeviceKeySupport.available) {
      throw const FingerprintUnavailableException();
    }
    final profile = await _auth.profile();
    final userId = _auth.accountId;
    if (userId == null) throw const ServerException();

    final device = await _device.read();
    final challenge = await _askChallenge(device.deviceId);
    final key = await _store.create(
      attestationChallenge: _challengeBytes(challenge.challenge),
    );
    try {
      final signature = await _store.sign(
        DeviceKeyTexts.registration(
          challengeId: challenge.challengeId,
          challenge: challenge.challenge,
          deviceId: device.deviceId,
          userId: userId,
        ),
        prompt: prompt,
      );
      await callApi(
        () => _authenticated.authDeviceKeyRegister(
          body: DeviceKeyRegisterRequest(
            // Sent as typed: never trimmed.
            currentPassword: password,
            publicKey: key.publicKey,
            algorithm: AlgorithmEnum.es256,
            challengeId: challenge.challengeId,
            signature: signature,
            attestationChain: key.attestationChain,
          ),
        ),
        mapDeviceKeyRegisterFailure,
      );
    } on Object {
      // Nothing was registered: the key made for it is of no use.
      await _store.delete();
      rethrow;
    }
    await _writeLabel(
      FingerprintAccount(
        accountId: userId,
        name: profile.name,
        maskedEmail: maskEmail(profile.email),
      ),
    );
  }

  @override
  Future<void> disable() async {
    await callApi(_authenticated.authDeviceKeyRemoveCurrent, mapCommonFailure);
    await _forgetLocal();
  }

  @override
  Future<FingerprintAccount?> signInAccount() async {
    final label = await _readLabel();
    if (label == null) return null;
    if (!await _store.exists()) {
      // The system ended the key (a fingerprint was added or removed).
      await _forgetLocal();
      return null;
    }
    return label;
  }

  @override
  Future<void> signIn({required String prompt}) async {
    if (await _readLabel() == null) {
      throw const FingerprintRefusedException(FingerprintRefusal.signInFailed);
    }
    final device = await _device.read();
    final challenge = await _askChallenge(device.deviceId);
    final String signature;
    try {
      signature = await _store.sign(
        DeviceKeyTexts.signIn(
          challengeId: challenge.challengeId,
          challenge: challenge.challenge,
          deviceId: device.deviceId,
        ),
        prompt: prompt,
      );
    } on FingerprintKeyInvalidatedException {
      await _forgetLocal();
      rethrow;
    }

    final body = DeviceKeySignInRequest(
      challengeId: challenge.challengeId,
      signature: signature,
      device: await readDeviceRequest(_device),
      language: _language() == 'ar' ? LanguageEnum.ar : LanguageEnum.en,
      timeZone: await _timeZone.read(),
    );
    final answer = await callApi(
      () => _plain.authDeviceKeySignIn(body: body),
      mapDeviceKeySignInFailure,
    );
    await _startSession(answer);
  }

  @override
  Future<void> sync() async {
    try {
      if (!_auth.isSignedIn) return;
      if (_auth.accountId == null) await _auth.profile();
      final accountId = _auth.accountId;

      var label = await _readLabel();
      if (label != null && label.accountId != accountId) {
        // Another account signed in on this phone: its fingerprint is not
        // this one's to use.
        await _forgetLocal();
        label = null;
      }

      final mine = (await keys()).where((entry) => entry.isCurrent);
      if (mine.isEmpty) {
        // The server no longer knows the key: the password was changed, it
        // expired, or another phone removed it.
        if (label != null) await _forgetLocal();
        return;
      }
      if (label == null || !await _store.exists()) {
        // The server has a key this phone cannot use: take it off.
        await callApi(
          _authenticated.authDeviceKeyRemoveCurrent,
          mapCommonFailure,
        );
        await _forgetLocal();
      }
      // A server that cannot be reached leaves things as they are.
    } on Object {
      return;
    }
  }

  @override
  Future<List<DeviceKeyEntry>> keys() async {
    final list = await callApi(
      _authenticated.authDeviceKeyList,
      mapCommonFailure,
    );
    return [for (final key in list.results) ?_entryOf(key)];
  }

  @override
  Future<void> removeKey(String deviceId) async {
    // The server only knows an id in lower case.
    final id = deviceId.toLowerCase();
    try {
      await callApi(
        () => _authenticated.authDeviceKeyRemove(deviceId: id),
        // A path the server does not route (`404`, not JSON) means there is no
        // such key: it is gone, which is what was asked for.
        (failure) => failure.statusCode == 404
            ? const _AlreadyGone()
            : mapCommonFailure(failure),
      );
    } on _AlreadyGone {
      // Nothing to remove.
    }
    final device = await _device.read();
    if (device.deviceId == id) await _forgetLocal();
  }

  Future<DeviceKeyChallengeResponse> _askChallenge(String deviceId) {
    return callApi(
      () => _plain.authDeviceKeyChallenge(
        body: DeviceKeyChallengeRequest(deviceId: deviceId),
      ),
      mapCommonFailure,
    );
  }

  /// The 32 random bytes the server sent as base64url without padding.
  Uint8List _challengeBytes(String challenge) {
    try {
      return base64Url.decode(base64Url.normalize(challenge));
    } on FormatException {
      throw const ServerException();
    }
  }

  DeviceKeyEntry? _entryOf(DeviceKey key) {
    final platform = switch (key.platform) {
      PlatformEnum.android => DevicePlatform.android,
      PlatformEnum.ios => DevicePlatform.ios,
      // A key never belongs to a web session.
      _ => null,
    };
    if (platform == null) return null;
    return DeviceKeyEntry(
      id: key.id,
      deviceId: key.deviceId,
      deviceName: key.deviceName,
      platform: platform,
      attested: key.attested,
      isCurrent: key.isCurrent,
      createdAt: key.createdAt,
      lastUsedAt: key.lastUsedAt,
      expiresAt: key.expiresAt,
    );
  }

  Future<FingerprintAccount?> _readLabel() async {
    final text = await _secure.read(_accountKey);
    if (text == null) return null;
    try {
      final json = jsonDecode(text);
      if (json is! Map<String, dynamic>) return null;
      final id = json['id'];
      final name = json['name'];
      final email = json['email'];
      if (id is! String || name is! String || email is! String) return null;
      return FingerprintAccount(accountId: id, name: name, maskedEmail: email);
    } on FormatException {
      return null;
    }
  }

  Future<void> _writeLabel(FingerprintAccount account) {
    return _secure.write(
      _accountKey,
      jsonEncode({
        'id': account.accountId,
        'name': account.name,
        'email': account.maskedEmail,
      }),
    );
  }

  @override
  Future<void> forgetLocal() async {
    try {
      await _forgetLocal();
      // A key that cannot be deleted cannot be used without the server's
      // public half either, which the server removed with the account.
    } on Exception {
      return;
    }
  }

  Future<void> _forgetLocal() async {
    await _store.delete();
    await _secure.delete(_accountKey);
  }
}

/// The key to remove was not there.
final class _AlreadyGone implements Exception {
  const new();
}
