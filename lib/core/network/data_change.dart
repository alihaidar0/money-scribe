/// Why a repository tells its screens that the data moved.
enum DataChange {
  /// This device saved something. The screen keeps showing what it has while
  /// the new figures load, and keeps it when they do not come.
  saved,

  /// The source of the data itself changed, as when the demo panel switches
  /// the scenario. The screen starts over, with its loading state.
  replaced,
}
