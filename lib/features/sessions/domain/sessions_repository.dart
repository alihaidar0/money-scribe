import 'package:equatable/equatable.dart';
import 'package:money_scribe/features/sessions/domain/device_session.dart';
import 'package:money_scribe/features/sessions/domain/security_event.dart';

/// Why the server did not accept what the person typed.
enum SessionRefusal {
  /// The password is not the password of the account.
  wrongPassword,
}

/// Thrown when the server refuses something for a reason the person can act
/// on. Too many wrong passwords is a `TooManyRequestsException` with the wait.
final class SessionRefusedException implements Exception {
  const new(this.refusal);

  final SessionRefusal refusal;

  @override
  String toString() => 'SessionRefusedException($refusal)';
}

/// What signing out of the other devices did.
final class OthersSignedOut extends Equatable {
  const new({required this.sessionsEnded, required this.keysRemoved});

  /// The sessions that were ended.
  final int sessionsEnded;

  /// The fingerprint keys that were removed, those of phones that were signed
  /// out already included.
  final int keysRemoved;

  @override
  List<Object> get props => [sessionsEnded, keysRemoved];
}

/// Where the sessions and the security activity of the account come from: the
/// server. Every method can throw a `DataException` when the server cannot be
/// reached or fails.
abstract interface class SessionsRepository {
  /// Emits when the sessions may have changed without the app changing them,
  /// so a screen showing them loads them again.
  Stream<void> get changes;

  /// The sessions that are active, the current one first. The server allows at
  /// most ten.
  Future<List<DeviceSession>> active();

  /// A page of the sessions that ended in the last 90 days, newest sign-in
  /// first. [cursor] is what the previous page gave, or `null` for the first.
  Future<SessionsPage> ended({String? cursor});

  /// Ends the session [id] of another device. Ending a device also removes its
  /// fingerprint key and its push token. A session that is gone is ended
  /// already, so it does nothing. The session of this device is ended by
  /// signing out, not by this.
  Future<void> end(String id);

  /// Ends every session but this one and removes every fingerprint key but this
  /// device's, after checking the [password]. Throws a
  /// [SessionRefusedException] for a wrong one.
  Future<OthersSignedOut> endOthers({required String password});

  /// A page of the security activity of the last 90 days, newest first.
  /// [cursor] is what the previous page gave, or `null` for the first.
  Future<SecurityEventsPage> activity({String? cursor});
}
