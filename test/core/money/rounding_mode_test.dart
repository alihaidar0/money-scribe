import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/money/rounding_mode.dart';

int _divide(int numerator, int denominator, RoundingMode mode) {
  return divideRounded(
    BigInt.from(numerator),
    BigInt.from(denominator),
    mode,
  ).toInt();
}

void main() {
  // numerator / denominator, then the result for each mode, in the order:
  // halfAwayFromZero, halfEven, towardZero, awayFromZero, floor, ceiling.
  const cases = <(int, int, List<int>)>[
    (5, 2, [3, 2, 2, 3, 2, 3]), //     2.5
    (-5, 2, [-3, -2, -2, -3, -3, -2]), // -2.5
    (7, 2, [4, 4, 3, 4, 3, 4]), //     3.5
    (-7, 2, [-4, -4, -3, -4, -4, -3]), // -3.5
    (29, 10, [3, 3, 2, 3, 2, 3]), //   2.9
    (-29, 10, [-3, -3, -2, -3, -3, -2]), // -2.9
    (21, 10, [2, 2, 2, 3, 2, 3]), //   2.1
    (-21, 10, [-2, -2, -2, -3, -3, -2]), // -2.1
    (1, 3, [0, 0, 0, 1, 0, 1]), //     0.33
    (-1, 3, [0, 0, 0, -1, -1, 0]), //  -0.33
    (6, 3, [2, 2, 2, 2, 2, 2]), //     exact
    (0, 7, [0, 0, 0, 0, 0, 0]), //     zero
  ];

  for (final (numerator, denominator, expected) in cases) {
    group('$numerator / $denominator', () {
      for (final (index, mode) in RoundingMode.values.indexed) {
        test('${mode.name} is ${expected[index]}', () {
          expect(_divide(numerator, denominator, mode), expected[index]);
        });
      }
    });
  }

  test(
    'a negative denominator gives the same result as a negative numerator',
    () {
      for (final mode in RoundingMode.values) {
        expect(_divide(5, -2, mode), _divide(-5, 2, mode), reason: mode.name);
        expect(_divide(-5, -2, mode), _divide(5, 2, mode), reason: mode.name);
      }
    },
  );

  test('works beyond the range of a 53-bit number', () {
    final big = BigInt.parse('123456789012345678901234567890');

    expect(
      divideRounded(
        big * BigInt.from(3),
        BigInt.from(2),
        RoundingMode.halfEven,
      ),
      BigInt.parse('185185183518518518351851851835'),
    );
  });

  test('a zero denominator is an error', () {
    expect(
      () => divideRounded(BigInt.one, BigInt.zero, RoundingMode.halfEven),
      throwsArgumentError,
    );
  });
}
