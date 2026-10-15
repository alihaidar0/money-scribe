import 'package:meta/meta.dart';
import 'package:money_scribe/core/formatting/western_digits.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/rounding_mode.dart';

/// Thrown when two amounts of different currencies are combined without a
/// conversion. Names the currencies, never the amounts.
final class CurrencyMismatchException implements Exception {
  const new(this.left, this.right);

  final Currency left;
  final Currency right;

  @override
  String toString() => 'Cannot combine $left and $right without a conversion';
}

/// An amount of money: a whole number of minor units (kopecks, cents, ...) in
/// one [Currency]. There is no `double` anywhere: amounts add and subtract
/// exactly, and the only way to get a fraction of an amount is [scaled], which
/// rounds once, with an explicit [RoundingMode].
///
/// Amounts are limited to [maxMinorUnits] (fifteen digits), which every
/// platform, the web included, stores and formats exactly. Going beyond it
/// throws a [RangeError] instead of silently losing precision.
@immutable
final class Money implements Comparable<Money> {
  const new(this.minorUnits, this.currency)
    : assert(
        minorUnits >= -maxMinorUnits && minorUnits <= maxMinorUnits,
        'The amount is out of range',
      );

  const new zero(this.currency) : minorUnits = 0;

  /// The largest absolute amount, in minor units.
  static const maxMinorUnits = 999999999999999;

  /// How [scaled] rounds unless told otherwise. The rule is kept here, in one
  /// place, so changing it changes every calculation at once.
  static const RoundingMode defaultRounding = RoundingMode.halfAwayFromZero;

  final int minorUnits;
  final Currency currency;

  bool get isZero => minorUnits == 0;
  bool get isNegative => minorUnits < 0;
  bool get isPositive => minorUnits > 0;

  Money operator +(Money other) {
    _requireSameCurrency(other);
    return _withMinorUnits(minorUnits + other.minorUnits);
  }

  Money operator -(Money other) {
    _requireSameCurrency(other);
    return _withMinorUnits(minorUnits - other.minorUnits);
  }

  Money operator -() => Money(-minorUnits, currency);

  /// This amount [times] over, exact.
  Money operator *(int times) {
    return _fromBigInt(BigInt.from(minorUnits) * BigInt.from(times));
  }

  Money abs() => Money(minorUnits.abs(), currency);

  /// This amount times `numerator / denominator`, rounded once to a whole
  /// minor unit with [rounding]. For example 13 % of an amount is
  /// `amount.scaled(13, 100)`. Multiply everything out first and scale last,
  /// so that only one rounding happens in a formula.
  Money scaled(
    int numerator,
    int denominator, {
    RoundingMode rounding = defaultRounding,
  }) {
    return _fromBigInt(
      divideRounded(
        BigInt.from(minorUnits) * BigInt.from(numerator),
        BigInt.from(denominator),
        rounding,
      ),
    );
  }

  bool operator <(Money other) => compareTo(other) < 0;
  bool operator <=(Money other) => compareTo(other) <= 0;
  bool operator >(Money other) => compareTo(other) > 0;
  bool operator >=(Money other) => compareTo(other) >= 0;

  @override
  int compareTo(Money other) {
    _requireSameCurrency(other);
    return minorUnits.compareTo(other.minorUnits);
  }

  /// The amount as plain text with a point and no grouping, such as `-1234.50`
  /// (`1235` for a currency without fraction digits). Locale-independent, so
  /// it is what files and the server use; [tryParse] reads it back exactly.
  String toDecimalString() {
    final digits = currency.fractionDigits;
    final absolute = minorUnits.abs().toString().padLeft(digits + 1, '0');
    final whole = absolute.substring(0, absolute.length - digits);
    final fraction = digits == 0
        ? ''
        : '.${absolute.substring(absolute.length - digits)}';
    return '${isNegative ? '-' : ''}$whole$fraction';
  }

  /// Reads an amount typed by a person or stored by [toDecimalString]: an
  /// optional sign, digits, and optionally a `.` or `,` followed by at most
  /// [Currency.fractionDigits] digits. Digits may be Western or Arabic-Indic.
  /// Grouping separators are not accepted, and an amount that would need
  /// rounding is rejected, never silently rounded. Returns `null` for
  /// anything else.
  static Money? tryParse(String text, Currency currency) {
    final match = _plainAmount.firstMatch(WesternDigits.normalize(text.trim()));
    if (match == null) return null;
    final fraction = match.group(3) ?? '';
    if (fraction.length > currency.fractionDigits) return null;

    final digits =
        '${match.group(2)}'
                '${fraction.padRight(currency.fractionDigits, '0')}'
            .replaceFirst(_leadingZeros, '');
    if (digits.length > _maxDigits) return null;
    final value = int.parse(digits);
    return Money(match.group(1) == '-' ? -value : value, currency);
  }

  static final RegExp _plainAmount = RegExp(r'^([+-]?)(\d+)(?:[.,](\d+))?$');
  static final RegExp _leadingZeros = RegExp(r'^0+(?=\d)');
  static final int _maxDigits = maxMinorUnits.toString().length;

  void _requireSameCurrency(Money other) {
    if (other.currency != currency) {
      throw CurrencyMismatchException(currency, other.currency);
    }
  }

  Money _withMinorUnits(int value) => _fromBigInt(BigInt.from(value));

  Money _fromBigInt(BigInt value) {
    if (value.abs() > BigInt.from(maxMinorUnits)) {
      throw RangeError('The amount is out of range');
    }
    return Money(value.toInt(), currency);
  }

  @override
  bool operator ==(Object other) =>
      other is Money &&
      other.minorUnits == minorUnits &&
      other.currency == currency;

  @override
  int get hashCode => Object.hash(minorUnits, currency);

  @override
  String toString() => 'Money(${toDecimalString()} $currency)';
}
