/// What a screen shows the figures of: the whole month, or one of the two
/// parts of a month that is paid in two payments (the 1st-15th and the
/// 16th-end).
enum PeriodScope {
  month,
  firstPart,
  secondPart;

  /// The last day of the first part: the 1st to the 15th.
  static const lastDayOfFirstPart = 15;

  /// The part a day of the month belongs to, going by the calendar halves.
  static PeriodScope partOfDay(int dayOfMonth) {
    return dayOfMonth <= lastDayOfFirstPart ? firstPart : secondPart;
  }
}
