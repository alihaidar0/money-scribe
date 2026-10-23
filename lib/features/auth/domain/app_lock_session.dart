/// Whether the app is locked now. The lock gate of the app decides when the
/// app locks (at start and after the time in the background); the screens only
/// report that the person opened it again.
abstract interface class AppLockSession {
  /// Whether the app is locked.
  bool get isLocked;

  /// Emits whenever [isLocked] changes.
  Stream<bool> get changes;

  /// The PIN or the fingerprint was right: the app opens.
  void unlock();
}
