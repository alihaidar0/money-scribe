import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final pubspec = File('pubspec.yaml').readAsStringSync();

  group('bundled fonts', () {
    for (final (family, weights) in [
      ('Inter', ['Regular', 'Medium', 'SemiBold']),
      ('IBMPlexSansArabic', ['Regular', 'Medium', 'SemiBold']),
    ]) {
      test('$family ships weights 400, 500 and 600 with its licence', () {
        for (final weight in weights) {
          final asset = 'assets/fonts/$family-$weight.ttf';

          expect(File(asset).existsSync(), isTrue, reason: '$asset exists');
          expect(pubspec, contains('- asset: $asset'));
        }
        expect(File('assets/fonts/$family-LICENSE.txt').existsSync(), isTrue);
      });
    }
  });
}
