/// Why a repository could not do what it was asked, in terms every screen
/// understands. A repository throws one of these, a Bloc turns it into a state,
/// and the screen shows the "No connection" or "Something went wrong" view.
sealed class DataException implements Exception {
  const new();
}

/// The server could not be reached.
final class NoConnectionException extends DataException {
  const new();

  @override
  String toString() => 'NoConnectionException';
}

/// The server answered with a failure.
final class ServerException extends DataException {
  const new();

  @override
  String toString() => 'ServerException';
}

/// The server does not offer this yet: the screen exists, the server side is
/// still to come (resetting or changing a password, deleting the account). It
/// goes away with the server's own endpoint, and no retry helps.
final class FeatureNotAvailableException extends DataException {
  const new();

  @override
  String toString() => 'FeatureNotAvailableException';
}

/// The server is working but cannot take the request right now (the answer
/// `503`). It refused the request before changing anything, so asking again
/// shortly is safe.
final class ServiceUnavailableException extends DataException {
  const new();

  @override
  String toString() => 'ServiceUnavailableException';
}

/// The record was changed since the app read it, on another device or from
/// another screen (the answer `412 precondition_failed`). Nothing was changed:
/// the app reads the record again and the person decides what to do.
final class StaleRecordException extends DataException {
  const new();

  @override
  String toString() => 'StaleRecordException';
}

/// The first try of the same action is still running on the server (the answer
/// `409 idempotency_in_progress`). Nothing was done twice: trying again a
/// moment later gets the answer of the first try.
final class RequestInProgressException extends DataException {
  const new();

  @override
  String toString() => 'RequestInProgressException';
}

/// The server asks the app to slow down (the answer `429`) and says for how
/// long: the control that caused the request stays disabled until then.
/// Nothing was changed.
final class TooManyRequestsException extends DataException {
  const new(this.retryAfter);

  /// How long until the same request may be made again (`Retry-After`).
  final Duration retryAfter;

  @override
  String toString() => 'TooManyRequestsException';
}
