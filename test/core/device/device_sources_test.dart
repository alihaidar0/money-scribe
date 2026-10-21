import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/device/platform_device_info_source.dart';
import 'package:money_scribe/core/device/time_zone_source.dart';

void main() {
  group('the length limits of the device object', () {
    test('a short text is kept', () {
      expect(PlatformDeviceInfoSource.clip('Pixel 8', 100), 'Pixel 8');
    });

    test('a long text is cut to the limit', () {
      final clipped = PlatformDeviceInfoSource.clip('x' * 150, 100);

      expect(clipped, hasLength(100));
    });

    test('the limits are the ones of the contract', () {
      expect(PlatformDeviceInfoSource.maxNameLength, 100);
      expect(PlatformDeviceInfoSource.maxVersionLength, 50);
    });
  });

  group('the time zone name', () {
    test('an IANA name is kept', () {
      expect(
        PlatformTimeZoneSource.validName('Europe/Berlin'),
        'Europe/Berlin',
      );
      expect(PlatformTimeZoneSource.validName('UTC'), 'UTC');
      expect(
        PlatformTimeZoneSource.validName('America/Argentina/Buenos_Aires'),
        'America/Argentina/Buenos_Aires',
      );
      expect(PlatformTimeZoneSource.validName('Etc/GMT+3'), 'Etc/GMT+3');
    });

    test('spaces around it are dropped', () {
      expect(
        PlatformTimeZoneSource.validName(' Europe/Berlin '),
        'Europe/Berlin',
      );
    });

    test('is left out when it cannot be used', () {
      expect(PlatformTimeZoneSource.validName(''), isNull);
      expect(PlatformTimeZoneSource.validName('   '), isNull);
      expect(PlatformTimeZoneSource.validName('Not A Zone'), isNull);
      expect(PlatformTimeZoneSource.validName('GMT+03:00'), isNull);
      expect(PlatformTimeZoneSource.validName('x' * 65), isNull);
    });

    test('at the limit of 64 characters it is kept', () {
      expect(PlatformTimeZoneSource.validName('x' * 64), hasLength(64));
    });
  });
}
