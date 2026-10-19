// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/code_sent.dart';
import '../models/profile.dart';
import '../models/refresh_request.dart';
import '../models/refresh_response.dart';
import '../models/register_request.dart';
import '../models/register_response.dart';
import '../models/resend_code_request.dart';
import '../models/sign_in_request.dart';
import '../models/sign_out_request.dart';
import '../models/signed_in_response.dart';
import '../models/verify_email_request.dart';

part 'auth_client.g.dart';

@RestApi()
abstract class AuthClient {
  factory AuthClient(Dio dio, {String? baseUrl}) = _AuthClient;

  /// Read the profile.
  ///
  /// The name and email of the signed-in user, and the `language` and `time_zone` stored from the device they last signed in on (read-only here). The app reads it after a restart, because the tokens carry no profile.
  @GET('/api/v1/auth/profile/')
  Future<Profile> authProfile();

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
  /// Starts a session. Errors: `401` `invalid_credentials` (an unknown email and a wrong password look the same), `403` `email_not_verified` (only after the right password; the app opens the verify screen), `429` `sign_in_locked` (even the right password, while locked; `Retry-After` is the remaining lock time) or `throttled`; `503` `service_unavailable` while the limit store is down, with `Retry-After`.
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
