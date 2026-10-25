/// A wait counted in whole seconds, as a countdown shows it.
extension DurationSeconds on Duration {
  /// The seconds in this duration, rounded up, so a wait of 1.2 seconds shows
  /// `2` and a countdown never reaches zero early.
  int get ceilSeconds => (inMilliseconds / 1000).ceil();
}
