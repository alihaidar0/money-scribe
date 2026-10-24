// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/change_password_request.dart';
import '../models/code_sent.dart';
import '../models/delete_account_request.dart';
import '../models/device_key.dart';
import '../models/device_key_challenge_request.dart';
import '../models/device_key_challenge_response.dart';
import '../models/device_key_list.dart';
import '../models/device_key_register_request.dart';
import '../models/device_key_sign_in_request.dart';
import '../models/email_change_confirm_request.dart';
import '../models/email_change_request_request.dart';
import '../models/email_change_response.dart';
import '../models/password_reset_confirm_request.dart';
import '../models/password_reset_request_request.dart';
import '../models/password_reset_verify_request.dart';
import '../models/patched_profile_update_request.dart';
import '../models/profile.dart';
import '../models/refresh_request.dart';
import '../models/refresh_response.dart';
import '../models/register_request.dart';
import '../models/register_response.dart';
import '../models/resend_code_request.dart';
import '../models/reset_token_response.dart';
import '../models/sign_in_request.dart';
import '../models/sign_out_request.dart';
import '../models/signed_in_response.dart';
import '../models/verify_email_request.dart';

part 'auth_client.g.dart';

@RestApi()
abstract class AuthClient {
  factory AuthClient(Dio dio, {String? baseUrl}) = _AuthClient;

  /// Delete the account.
  ///
  /// Needs the password. Deletes the account and **all** its data at once and for good, in one transaction, and every session ends with it (the tokens stop working at once). Nothing is kept: no soft delete and no anonymised copy. The address is used only for a confirmation email. It is `POST` with a body, not `DELETE`, because a `DELETE` body has no defined meaning and proxies may drop it. Errors: `400` `invalid_password` (`attr` `password`); `429` `password_attempts_exceeded` (shared with the password change) or `throttled`, each with `Retry-After`; `503` `service_unavailable` while the limit store is down, with `Retry-After`.
  @POST('/api/v1/auth/account/delete/')
  Future<void> authAccountDelete({@Body() required DeleteAccountRequest body});

  /// List the fingerprint sign-in keys.
  ///
  /// The person's own keys, newest first, with `is_current` on the one of the calling device. A signed-out phone has no session but may still hold a key, so the keys have their own list. An account with none is `200` with an empty `results`. The list holds at most 5 keys, so it is one page in the envelope of every list (`next` and `previous` are `null`); it moves onto the cursor class without a change of shape.
  @GET('/api/v1/auth/device-keys/')
  Future<DeviceKeyList> authDeviceKeyList();

  /// Remove the fingerprint sign-in key of a device.
  ///
  /// Deletes the person's key of that device, for example a lost phone's, from another device. It answers `204` also when there is none, and for a `device_id` that is not theirs it changes nothing and answers the same, so the call reveals nothing about other accounts.
  @DELETE('/api/v1/auth/device-keys/{device_id}/')
  Future<void> authDeviceKeyRemove({
    @Path('device_id') required String deviceId,
  });

  /// Ask for a challenge to sign.
  ///
  /// Step 1 of a fingerprint sign-in, and of registering a key. Answers 32 random bytes (`challenge`, base64url without padding) and their `challenge_id`; the challenge lives 2 minutes and works once. The answer has the same shape for every `device_id`, known or not, so it reveals nothing. Sign the text of ADR 0018 that contains the challenge exactly as sent. Errors: `429` `throttled` with `Retry-After`; `503` `service_unavailable` while the limit store is down, with `Retry-After`.
  @POST('/api/v1/auth/device-keys/challenge/')
  Future<DeviceKeyChallengeResponse> authDeviceKeyChallenge({
    @Body() required DeviceKeyChallengeRequest body,
  });

  /// Register the fingerprint sign-in key of this device.
  ///
  /// Step 2 of 2 (after `auth_device_key_challenge`). Registers the public key of the calling session's device, or replaces the one it had, also when another account held it. Needs the current password. The signature proves the phone holds the private key: it signs `money-scribe/device-key-registration/v1`, the `challenge_id`, the challenge, the `device_id` and the account id, joined by newlines. An Android key also needs its attestation chain, whose challenge is the 32 raw bytes of the challenge. The owner is emailed. `201` for a new key, `200` for a replaced one. Errors: `400` `invalid_password` (`attr` `current_password`), `challenge_invalid` (`attr` `challenge_id`: unknown, used or expired, asked for another device, or a wrong proof), `public_key_invalid` (`attr` `public_key`), `attestation_invalid` (`attr` `attestation_chain`; no reason is given) or `platform_not_supported` (a `web` session); `409` `device_key_limit_reached` (the account has 5 keys); `429` `password_attempts_exceeded` (the lock shared with the password change) or `throttled`, each with `Retry-After`; `503` `service_unavailable` while the limit store is down, or when Google's revocation list cannot be reached, with `Retry-After`.
  @PUT('/api/v1/auth/device-keys/current/')
  Future<DeviceKey> authDeviceKeyRegister({
    @Body() required DeviceKeyRegisterRequest body,
  });

  /// Turn off fingerprint sign-in on this device.
  ///
  /// Deletes the key of the calling session's device. It answers `204` also when there is none.
  @DELETE('/api/v1/auth/device-keys/current/')
  Future<void> authDeviceKeyRemoveCurrent();

  /// Sign in with the device key.
  ///
  /// Starts a session from a signature made with the hardware key of this device, with no password and no email: the key identifies the account. The signed text is `money-scribe/device-sign-in/v1`, the `challenge_id`, the challenge exactly as sent and the `device_id`, joined by newlines. The answer is the one of `auth_sign_in`. Errors: every failure is one `401` `device_sign_in_failed` (unknown device, a challenge that is unknown, used, expired or asked for another device, a bad signature, an expired key, an inactive account), so the app shows the password form; `429` `sign_in_locked` after 5 failures from the device or 20 from the client address in 15 minutes (its own lock, apart from the password one) or `throttled`, each with `Retry-After`; `503` `service_unavailable` while the limit store is down, with `Retry-After`.
  @POST('/api/v1/auth/device-keys/sign-in/')
  Future<SignedInResponse> authDeviceKeySignIn({
    @Body() required DeviceKeySignInRequest body,
  });

  /// Start an email change.
  ///
  /// Step 1 of 2. Emails a 6-digit code to the **new** address; the old one stays in force until the code is accepted by `auth_email_change_confirm`. Needs the current password. A new request replaces the earlier pending change. Errors: `400` `invalid_password` (`attr` `current_password`), `email_unchanged` (`attr` `email`: the account already has it), or `invalid` for a malformed address; `409` `email_already_registered` (a signed-in caller who has proved the password may be told; no other call says so); `429` `password_attempts_exceeded` (the password lock shared with the password change), `resend_too_soon` (60 second cooldown for the new address), `resend_limit_reached` (5 codes per hour for the address, and 5 changes per hour for the account) or `throttled`, each with `Retry-After`; `503` `service_unavailable` while the limit store is down, with `Retry-After`.
  @POST('/api/v1/auth/email-change/')
  Future<EmailChangeResponse> authEmailChangeRequest({
    @Body() required EmailChangeRequestRequest body,
  });

  /// Cancel the pending email change.
  ///
  /// Drops the pending change, so its code stops working. It answers `204` also when nothing is pending.
  @DELETE('/api/v1/auth/email-change/')
  Future<void> authEmailChangeCancel();

  /// Confirm the email change.
  ///
  /// Step 2 of 2. A correct code switches the sign-in address to the new one, ends every **other** session (this one continues, with the same tokens), tells the old address by email and answers the updated profile. Errors: `400` `code_invalid` (the error item carries `attempts_left`) or `code_expired` (also when no change is pending); `409` `email_already_registered` (the address was taken meanwhile; the code is kept); `429` `code_attempts_exceeded` (the code is dead; `Retry-After` is the wait before a new one may be requested) or `throttled`; `503` `service_unavailable` while the limit store is down, with `Retry-After`.
  @POST('/api/v1/auth/email-change/confirm/')
  Future<Profile> authEmailChangeConfirm({
    @Body() required EmailChangeConfirmRequest body,
  });

  /// Set the new password.
  ///
  /// Step 3 of 3. Sets the new password with the `reset_token` and ends **all** the user's sessions, so the app returns to the sign-in screen (it signs nobody in). The owner gets an email about the change. Errors: `400` `reset_token_invalid` (`attr` `reset_token`: unknown, used or expired; ask for a new code), or a password rule on `attr` `password` (`password_too_short`, `password_too_long`, `password_too_similar`, `password_too_common`, `password_compromised`), after which the same token may be used again until it expires. A new password equal to the current one is allowed here: the reset proves the mailbox, not the old password. `429` `throttled` with `Retry-After`; `503` `service_unavailable` while the limit store is down, with `Retry-After`.
  @POST('/api/v1/auth/password-reset/confirm/')
  Future<void> authPasswordResetConfirm({
    @Body() required PasswordResetConfirmRequest body,
  });

  /// Ask for a password reset code.
  ///
  /// Step 1 of 3. Emails a 6-digit code to a registered, verified address. The answer is the same for every address, whether it has an account or not, so it reveals nothing; the app always goes on to the code screen. The code lives 10 minutes and shares the hourly budget of the other codes. Errors: `429` `resend_too_soon` (the 60 second cooldown), `resend_limit_reached` (5 codes per hour) or `throttled`, each with `Retry-After`; `503` `service_unavailable` while the limit store is down, with `Retry-After`.
  @POST('/api/v1/auth/password-reset/request/')
  Future<CodeSent> authPasswordResetRequest({
    @Body() required PasswordResetRequestRequest body,
  });

  /// Check the password reset code.
  ///
  /// Step 2 of 3. A correct code is spent and answered with a single-use `reset_token` that lives 10 minutes. It does not sign anyone in. Errors: `400` `code_invalid` (the error item carries `attempts_left`) or `code_expired`, `429` `code_attempts_exceeded` (the code is dead; `Retry-After` is the wait before a new one may be requested) or `throttled`; `503` `service_unavailable` while the limit store is down, with `Retry-After`. The answers are the same for an address with no account.
  @POST('/api/v1/auth/password-reset/verify/')
  Future<ResetTokenResponse> authPasswordResetVerify({
    @Body() required PasswordResetVerifyRequest body,
  });

  /// Change the password.
  ///
  /// Needs the current password. Ends every **other** session; this one continues with the new token pair in the answer, and the previous refresh token is retired. The owner gets an email about the change. Errors: `400` `invalid_password` (`attr` `current_password`: it is `400`, not `401`, so the app's session handling is not triggered), `password_unchanged` (`attr` `password`: the new password equals the current one), or a password rule on `attr` `password` (`password_too_short`, `password_too_long`, `password_too_similar`, `password_too_common`, `password_compromised`); `429` `password_attempts_exceeded` (5 wrong current passwords lock this operation and the account deletion for 15 minutes; `Retry-After` is the remaining time; sign-in is unaffected) or `throttled`; `503` `service_unavailable` while the limit store is down, with `Retry-After`.
  @POST('/api/v1/auth/password/change/')
  Future<RefreshResponse> authPasswordChange({
    @Body() required ChangePasswordRequest body,
  });

  /// Read the profile.
  ///
  /// The name and email of the signed-in user, and the `language` and `time_zone` stored from the device they last signed in on (read-only here). The app reads it after a restart, because the tokens carry no profile.
  @GET('/api/v1/auth/profile/')
  Future<Profile> authProfile();

  /// Edit the name.
  ///
  /// Changes the display name and answers the updated profile. Only `name` can be sent: any other field, such as `email`, `language` or `time_zone`, is refused with `400` and the code `read_only` on that field (the email changes only through `auth_email_change_request`). Errors: `400` `blank`, `required` or `max_length` on `name`.
  @PATCH('/api/v1/auth/profile/')
  Future<Profile> authProfileUpdate({
    @Body() PatchedProfileUpdateRequest? body,
  });

  /// Refresh the tokens.
  ///
  /// Trades the single-use refresh token for a new access token and a new refresh token. If the answer is lost, the same refresh token sent again within 30 seconds of the rotation returns the same new pair; an older used token ends the session. Errors: `401` `token_invalid`, `session_expired`, `session_signed_out`, `session_revoked_by_user`, `session_password_changed`, `session_email_changed` or `session_token_reuse`; all are final, so sign in again.
  @POST('/api/v1/auth/refresh/')
  Future<RefreshResponse> authRefresh({@Body() required RefreshRequest body});

  /// Register an account.
  ///
  /// Creates an unverified account and emails a 6-digit code. No session is created: the code is verified with `auth_verify_email`, which signs the user in. The answer is the same whether the address is new, pending or already registered, so it reveals nothing: a pending address is registered again (the new name and password replace the earlier ones), and the owner of a registered address gets an email saying someone tried, with no code. Errors: `400` field errors (password: `password_too_short`, `password_too_long`, `password_too_similar`, `password_too_common`, `password_compromised`; `invalid` for an email), `429` `resend_too_soon` or `resend_limit_reached` or `throttled`, each with `Retry-After`; `503` `service_unavailable` while the limit store is down, with `Retry-After`.
  @POST('/api/v1/auth/register/')
  Future<RegisterResponse> authRegister({
    @Body() required RegisterRequest body,
  });

  /// Send a new code.
  ///
  /// Emails a new code, which replaces every earlier one. The answer is the same for every address, so it reveals nothing. Errors: `429` `resend_too_soon` (the 60 second cooldown), `resend_limit_reached` (5 codes per hour) or `throttled`, each with `Retry-After`; `503` `service_unavailable` while the limit store is down, with `Retry-After`.
  @POST('/api/v1/auth/resend-code/')
  Future<CodeSent> authResendCode({@Body() required ResendCodeRequest body});

  /// Sign in.
  ///
  /// Starts a session. A client address that has failed several sign-ins is first asked for a bot challenge: `400` `captcha_required` (`attr` `captcha_token`) until it sends the token of a solved Turnstile widget (action `sign_in`) as `captcha_token`, `400` `captcha_invalid` for a token that is wrong, expired or used (it counts as a failed attempt); the token is single use, so a repeated attempt needs a new one. The email is looked up next. Errors: `401` `email_not_registered` (`attr` `email`: no account has it, whatever the password is, even blank), `401` `wrong_password` (`attr` `password`: the email has an account and the password is wrong), `401` `invalid_credentials` (any other failed sign-in, such as a deactivated account), `403` `email_not_verified` (only after the right password; the app opens the verify screen), `429` `sign_in_locked` (even the right password, while the account or the client address is locked; `Retry-After` is the remaining lock time) or `throttled`; `503` `service_unavailable` while the limit store is down, with `Retry-After`. Telling an unknown email from a wrong password lets anyone learn which emails have an account (ADR 0012); the limits are the brake, so a client must not retry automatically.
  @POST('/api/v1/auth/sign-in/')
  Future<SignedInResponse> authSignIn({@Body() required SignInRequest body});

  /// Sign out.
  ///
  /// Ends the session at once. Send the bearer access token, or, when it has expired, the `refresh_token` in the body, so the device need not refresh first. Signing out a session that has already ended is not an error when the `refresh_token` is sent: it answers `204`, and so does a second call with the same `refresh_token`. Errors: `401`, and the `code` depends on what was sent. With the access token only: `token_expired` (refresh, or send the `refresh_token`), `token_invalid`, or the code of the session's end (`session_signed_out`, `session_revoked_by_user`, `session_password_changed`, `session_email_changed`, `session_token_reuse` or `session_expired`; the session is over, so the device is already signed out). With a `refresh_token` in the body: only `token_invalid`, when neither token is valid. It never answers `503`.
  @POST('/api/v1/auth/sign-out/')
  Future<void> authSignOut({@Body() SignOutRequest? body});

  /// Verify the email and sign in.
  ///
  /// A correct code verifies the address and starts the session, so the app goes straight in. Errors: `400` `code_invalid` (the error item carries `attempts_left`) or `code_expired`, `429` `code_attempts_exceeded` (the code is dead; `Retry-After` is the wait before a new one may be requested) or `throttled`; `503` `service_unavailable` while the limit store is down, with `Retry-After`.
  @POST('/api/v1/auth/verify-email/')
  Future<SignedInResponse> authVerifyEmail({
    @Body() required VerifyEmailRequest body,
  });
}
