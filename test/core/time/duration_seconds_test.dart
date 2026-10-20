import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/time/duration_seconds.dart';

void main() {
  group('ceilSeconds', () {
    test('is exact for whole seconds', () {
      expect(const Duration(seconds: 60).ceilSeconds, 60);
      expect(const Duration(hours: 1).ceilSeconds, 3600);
      expect(Duration.zero.ceilSeconds, 0);
    });

    test('rounds a part of a second up, so a countdown never ends early', () {
      expect(const Duration(milliseconds: 1).ceilSeconds, 1);
      expect(const Duration(milliseconds: 1200).ceilSeconds, 2);
      expect(const Duration(milliseconds: 59001).ceilSeconds, 60);
    });
  });
}
