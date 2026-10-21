/// What the app knows about how fast the server answers.
abstract interface class ServerActivity {
  /// Whether a request has been waiting for the server for long enough to tell
  /// the person to be patient.
  bool get isSlow;

  /// Emits whenever [isSlow] changes.
  Stream<bool> get slowChanges;
}
