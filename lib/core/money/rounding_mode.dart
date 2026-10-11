/// How a fraction of a minor unit is rounded. All rounding of money goes
/// through [divideRounded]: nothing else rounds an amount.
enum RoundingMode {
  /// To the nearest; a tie goes away from zero (2.5 → 3, -2.5 → -3). The
  /// everyday "commercial" rounding, and the default.
  halfAwayFromZero,

  /// To the nearest; a tie goes to the even neighbour (2.5 → 2, 3.5 → 4).
  halfEven,

  /// Drops the fraction (2.9 → 2, -2.9 → -2).
  towardZero,

  /// Any fraction goes up in size (2.1 → 3, -2.1 → -3).
  awayFromZero,

  /// Towards negative infinity (2.9 → 2, -2.1 → -3).
  floor,

  /// Towards positive infinity (2.1 → 3, -2.9 → -2).
  ceiling,
}

/// [numerator] divided by [denominator], rounded to a whole number with [mode].
/// The one place where an amount is rounded; works on any platform because it
/// uses [BigInt].
BigInt divideRounded(BigInt numerator, BigInt denominator, RoundingMode mode) {
  if (denominator == BigInt.zero) {
    throw ArgumentError.value(denominator, 'denominator', 'must not be zero');
  }
  final quotient = numerator ~/ denominator; // truncates towards zero
  final remainder = numerator.remainder(denominator);
  if (remainder == BigInt.zero) return quotient;

  final negative = numerator.sign * denominator.sign < 0;
  final comparedToHalf = (remainder.abs() * BigInt.two).compareTo(
    denominator.abs(),
  );
  final away = switch (mode) {
    RoundingMode.towardZero => false,
    RoundingMode.awayFromZero => true,
    RoundingMode.floor => negative,
    RoundingMode.ceiling => !negative,
    RoundingMode.halfAwayFromZero => comparedToHalf >= 0,
    RoundingMode.halfEven =>
      comparedToHalf > 0 || (comparedToHalf == 0 && quotient.isOdd),
  };
  return away ? quotient + BigInt.from(negative ? -1 : 1) : quotient;
}
