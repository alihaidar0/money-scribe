import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/features/auth/domain/device_key.dart';
import 'package:money_scribe/features/auth/domain/device_key_texts.dart';

void main() {
  group('maskEmail', () {
    test('keeps the first letter and the domain', () {
      expect(maskEmail('alex@gmail.com'), 'a***@gmail.com');
    });

    test('hides a one-letter name the same way', () {
      expect(maskEmail('a@gmail.com'), 'a***@gmail.com');
    });

    test('uses the last @ so a quoted name cannot leak', () {
      expect(maskEmail('"a@b"@gmail.com'), '"***@gmail.com');
    });

    test('hides something that is not an address completely', () {
      expect(maskEmail('nonsense'), '***');
      expect(maskEmail(''), '***');
      expect(maskEmail('@gmail.com'), '***');
    });
  });

  group('the signed texts', () {
    test('a sign-in joins its four lines with no trailing newline', () {
      expect(
        DeviceKeyTexts.signIn(
          challengeId: 'id-1',
          challenge: 'abc-_',
          deviceId: 'device-1',
        ),
        'money-scribe/device-sign-in/v1\nid-1\nabc-_\ndevice-1',
      );
    });

    test('a registration adds the account id, in lower case', () {
      expect(
        DeviceKeyTexts.registration(
          challengeId: 'id-1',
          challenge: 'abc-_',
          deviceId: 'device-1',
          userId: 'ABCD-EF',
        ),
        'money-scribe/device-key-registration/v1\n'
        'id-1\nabc-_\ndevice-1\nabcd-ef',
      );
    });

    test('the two start differently, so one can never stand for the other', () {
      expect(
        DeviceKeyTexts.signInContext,
        isNot(DeviceKeyTexts.registrationContext),
      );
    });
  });
}
