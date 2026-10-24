/// The texts the phone signs for the server. Both are UTF-8, lines joined by
/// `\n` with no trailing newline, and carry the `challenge` exactly as the
/// server sent it (base64url). The first line says what the signature is for,
/// so one made for registering can never sign anybody in.
abstract final class DeviceKeyTexts {
  static const signInContext = 'money-scribe/device-sign-in/v1';
  static const registrationContext = 'money-scribe/device-key-registration/v1';

  /// What a sign-in signs.
  static String signIn({
    required String challengeId,
    required String challenge,
    required String deviceId,
  }) {
    return [signInContext, challengeId, challenge, deviceId].join('\n');
  }

  /// What registering a key signs. [userId] is the account id in lower case.
  static String registration({
    required String challengeId,
    required String challenge,
    required String deviceId,
    required String userId,
  }) {
    return [
      registrationContext,
      challengeId,
      challenge,
      deviceId,
      userId.toLowerCase(),
    ].join('\n');
  }
}
