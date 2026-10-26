// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/paginated_security_event_list.dart';
import '../models/paginated_session_list.dart';
import '../models/revoke_others_request.dart';
import '../models/revoke_others_result.dart';
import '../models/status.dart';

part 'sessions_client.g.dart';

@RestApi()
abstract class SessionsClient {
  factory SessionsClient(Dio dio, {String? baseUrl}) = _SessionsClient;

  /// The security activity of the account.
  ///
  /// What happened to the account, newest first (`occurred_at`, `id`), in pages (`limit` 50 by default, 100 at most). Entries are kept 90 days; an older one is never returned, even before the purge has run. The types are `signed_in`, `signed_out`, `session_revoked`, `session_limit_reached`, `password_changed`, `password_reset`, `email_changed`, `device_key_added`, `device_key_removed`, `token_reuse_detected`, `data_exported` and `data_imported`; a client treats an unknown type, platform or sign-in method as an open value. **Which device an entry carries:** for `signed_in`, `signed_out`, `password_changed`, `email_changed`, `data_exported` and `data_imported` the device where the action was done; for `session_revoked`, `session_limit_reached` and `token_reuse_detected` the device of the session that was ended (`session_id` is that session); for `device_key_added` and `device_key_removed` the device of the key (`app_version` is `null` when the acting session is on another device); `password_reset` has no session, so its device fields are `null`. **Imports of long files:** an entry is never edited or merged on the server, and an import writes one `data_imported` entry for each call that writes at least one row (at most 500 rows), so a file of 10 000 rows is up to 20 entries; the app may show consecutive entries of the same `session_id`, less than 15 minutes apart, as one. No IP address, user agent, amount, note or name is in an entry. Failed sign-ins and the deletion of the account are not entries.
  ///
  /// [cursor] - An opaque position taken from `next` or `previous`; never built by the client.
  ///
  /// [limit] - How many results a page holds: 50 by default, at most 100.
  @GET('/api/v1/auth/session-history/')
  Future<PaginatedSecurityEventList> authSessionHistory({
    @Query('cursor') String? cursor,
    @Query('limit') int? limit,
  });

  /// The sessions of the account.
  ///
  /// `status=active` (the default) is the live sessions: the current one first, then the most recently active, at most 10, always the whole list with `next` and `previous` `null` (`limit` and `cursor` are accepted and ignored). A session is live when it has not been ended and its refresh token has not expired. `status=ended` is the sessions that ended in the last 90 days (never older, even before the daily purge has run), newest sign-in first, in pages (`limit` 50 by default, 100 at most). Every sign-in is a session, so a device that signed in five times has five rows with the same `device_id`; the app groups them. A session nobody used for 30 days counts as ended with `end_reason` `expired` and `ended_at` the moment its refresh token ran out; nothing is written for that. `limit` that is not a whole number of at least 1 is `400` `invalid`; a `status` that is not one of the two is `400` `invalid_choice`.
  ///
  /// [cursor] - An opaque position taken from `next` or `previous`; never built by the client.
  ///
  /// [limit] - How many results a page holds: 50 by default, at most 100.
  ///
  /// [status] - `active` (the default): the live sessions, the current one first, at most 10, always the whole list in the cursor envelope. `ended`: the sessions that ended in the last 90 days, newest sign-in first, in pages.
  ///
  /// * `active` - active.
  /// * `ended` - ended.
  @GET('/api/v1/auth/sessions/')
  Future<PaginatedSessionList> authSessionList({
    @Query('status') Status? status = Status.active,
    @Query('cursor') String? cursor,
    @Query('limit') int? limit,
  });

  /// End a session.
  ///
  /// Ends one of the person's own sessions (`204`). A session that is already over is also `204` and nothing changes. An id that is not theirs, or does not exist, is `404`. Ending the **current** session is a sign-out (the fingerprint key stays; the app uses the sign-out call for this). Ending **another** session makes that device answer `401` `session_revoked_by_user` on its next call, records a `session_revoked` entry in the security activity, and removes the fingerprint key of that session's device (unless it is the current device's) in the same transaction; there is no opt-out and the answer has no body. It counts in the session actions rate group (30 an hour) and keeps working while the limit store is down, because it only reduces access.
  ///
  /// [id] - The session id.
  @DELETE('/api/v1/auth/sessions/{id}/')
  Future<void> authSessionEnd({@Path('id') required String id});

  /// End every other session.
  ///
  /// Needs the password. Ends every session but the current one and removes every fingerprint key but the current device's, the keys of signed-out phones included, in one transaction. Answers `200` with how many of each; with no other sessions `ended` is 0 and the keys of other devices are still removed. A wrong password is `400` `invalid_password` on `current_password`; too many wrong ones are `429` `password_attempts_exceeded` (the lock shared with the password change); a field that is not `current_password` is `400` `read_only`. It counts in the session actions rate group (30 an hour) and fails closed: `503` `service_unavailable` while the limit store is down.
  @POST('/api/v1/auth/sessions/revoke-others/')
  Future<RevokeOthersResult> authSessionRevokeOthers({
    @Body() required RevokeOthersRequest body,
  });
}
