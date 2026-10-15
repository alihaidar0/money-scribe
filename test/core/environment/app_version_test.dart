import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/environment/app_version.dart';

void main() {
  test('the version shown is the version of pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final match = RegExp(
      r'^version:\s*(\d+\.\d+\.\d+)',
      multiLine: true,
    ).firstMatch(pubspec);

    expect(match, isNotNull);
    expect(appVersion, match!.group(1));
  });
}
