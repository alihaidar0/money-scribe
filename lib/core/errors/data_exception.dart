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
