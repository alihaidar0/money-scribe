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

/// The server is working but cannot take the request right now (the answer
/// `503`). It refused the request before changing anything, so asking again
/// shortly is safe.
final class ServiceUnavailableException extends DataException {
  const new();

  @override
  String toString() => 'ServiceUnavailableException';
}
