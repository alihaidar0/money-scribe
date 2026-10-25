/// Why the fixed items of another month were not copied although the server
/// was reached. Each is a refusal that asking again does not change.
enum FixedItemsCopyRefusal {
  /// There is no saved month before this one to copy from (or this month is
  /// not saved).
  noEarlierMonth,

  /// The month would hold more fixed items than it may; nothing was copied.
  limitReached,

  /// The month to copy from is in another currency than this one.
  currencyMismatch,
}

/// A copy of fixed items that the server refused with a reason the person can
/// act on. Nothing was copied.
final class FixedItemsCopyRefusedException implements Exception {
  const new(this.refusal);

  final FixedItemsCopyRefusal refusal;

  @override
  String toString() => 'FixedItemsCopyRefusedException(${refusal.name})';
}
