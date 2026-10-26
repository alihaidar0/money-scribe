import 'package:dio/dio.dart';
import 'package:money_scribe/core/api/export.dart' as api;
import 'package:money_scribe/core/network/api_failure.dart';
import 'package:money_scribe/core/network/call_api.dart';
import 'package:money_scribe/core/network/paged.dart';
import 'package:money_scribe/features/sessions/data/remote/sessions_wire.dart';
import 'package:money_scribe/features/sessions/domain/device_session.dart';
import 'package:money_scribe/features/sessions/domain/security_event.dart';
import 'package:money_scribe/features/sessions/domain/sessions_repository.dart';

/// The sessions and the security activity on the server: the real
/// [SessionsRepository].
///
/// The active sessions are one page (the server allows ten). The ended sessions
/// and the activity are read a page at a time, following only an address on
/// the server's own origin. The server removes the fingerprint key and the push
/// token of a device whose session is ended.
class RemoteSessionsRepository implements SessionsRepository {
  new({required this._sessions, required this._baseUrl});

  /// The calls over [dio], which carries the token of the session and renews
  /// it.
  factory create({required Dio dio}) {
    return RemoteSessionsRepository(
      sessions: api.SessionsClient(dio),
      baseUrl: dio.options.baseUrl,
    );
  }

  /// How many ended sessions and activity entries a page holds.
  static const _pageSize = 50;

  final api.SessionsClient _sessions;
  final String _baseUrl;

  /// The server does not push changes, and the screens load again when the
  /// person comes back to them.
  @override
  Stream<void> get changes => const Stream<void>.empty();

  @override
  Future<List<DeviceSession>> active() async {
    final page = await callApi(_sessions.authSessionList, _map);
    return [for (final item in page.results) SessionsWire.session(item)];
  }

  @override
  Future<SessionsPage> ended({String? cursor}) async {
    final page = await callApi(
      () => _sessions.authSessionList(
        status: api.Status.ended,
        cursor: cursor,
        limit: _pageSize,
      ),
      _map,
    );
    return SessionsPage(
      items: [for (final item in page.results) SessionsWire.session(item)],
      nextCursor: cursorOfNextPage(page.next, baseUrl: _baseUrl),
    );
  }

  @override
  Future<void> end(String id) async {
    try {
      await callApi(
        () => _sessions.authSessionEnd(id: id),
        (failure) => failure.isNotFound ? const _Gone() : _map(failure),
      );
    } on _Gone {
      // Already ended: the person wanted it ended.
    }
  }

  @override
  Future<OthersSignedOut> endOthers({required String password}) async {
    final result = await callApi(
      // The password is sent exactly as typed.
      () => _sessions.authSessionRevokeOthers(
        body: api.RevokeOthersRequest(currentPassword: password),
      ),
      (failure) =>
          failure.statusCode == 400 && failure.hasCode('invalid_password')
          ? const SessionRefusedException(SessionRefusal.wrongPassword)
          : _map(failure),
    );
    return OthersSignedOut(
      sessionsEnded: result.ended,
      keysRemoved: result.deviceKeysRemoved,
    );
  }

  @override
  Future<SecurityEventsPage> activity({String? cursor}) async {
    final page = await callApi(
      () => _sessions.authSessionHistory(cursor: cursor, limit: _pageSize),
      _map,
    );
    return SecurityEventsPage(
      items: [for (final item in page.results) SessionsWire.event(item)],
      nextCursor: cursorOfNextPage(page.next, baseUrl: _baseUrl),
    );
  }

  Exception _map(ApiFailure failure) => failure.toDataException();
}

/// The answer was `404 not_found`: there is no such session.
final class _Gone implements Exception {
  const new();
}
