import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/features/auth/domain/pin_lockout_policy.dart';

void main() {
  group('the pause after wrong PINs', () {
    test('there is none for the first four', () {
      for (var failures = 0; failures < 5; failures++) {
        expect(PinLockoutPolicy.pauseAfter(failures), isNull);
      }
    });

    test('grows from the fifth on, like the lock screen of the phone', () {
      expect(PinLockoutPolicy.pauseAfter(5), const Duration(seconds: 30));
      expect(PinLockoutPolicy.pauseAfter(6), const Duration(minutes: 1));
      expect(PinLockoutPolicy.pauseAfter(7), const Duration(minutes: 5));
      expect(PinLockoutPolicy.pauseAfter(8), const Duration(minutes: 15));
      expect(PinLockoutPolicy.pauseAfter(9), const Duration(minutes: 15));
    });

    test('never shrinks as the wrong PINs add up', () {
      var longest = Duration.zero;
      for (
        var failures = 1;
        failures < PinLockoutPolicy.maxFailures;
        failures++
      ) {
        final pause = PinLockoutPolicy.pauseAfter(failures) ?? Duration.zero;
        expect(pause >= longest || pause == Duration.zero, isTrue);
        if (pause > longest) longest = pause;
      }
    });
  });

  group('too many wrong PINs', () {
    test('ten in a row is the limit', () {
      expect(PinLockoutPolicy.maxFailures, 10);
      expect(PinLockoutPolicy.isTooMany(9), isFalse);
      expect(PinLockoutPolicy.isTooMany(10), isTrue);
      expect(PinLockoutPolicy.isTooMany(11), isTrue);
    });
  });
}
