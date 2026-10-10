import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _readArb(String locale) {
  final file = File('lib/core/l10n/arb/app_$locale.arb');
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

Set<String> _messageKeys(Map<String, dynamic> arb) {
  return arb.keys.where((key) => !key.startsWith('@')).toSet();
}

Set<String> _placeholders(String message) {
  return RegExp(r'\{(\w+)').allMatches(message).map((m) => m[1]!).toSet();
}

void main() {
  final english = _readArb('en');
  final arabic = _readArb('ar');

  test('Arabic translates exactly the messages of the English template', () {
    expect(_messageKeys(arabic), _messageKeys(english));
  });

  test('every English message has a description for translators', () {
    for (final key in _messageKeys(english)) {
      final metadata = english['@$key'] as Map<String, dynamic>?;
      final description = metadata?['description'] as String?;

      expect(description, isNotEmpty, reason: 'missing description for $key');
    }
  });

  test('Arabic messages use the same placeholders as the English ones', () {
    for (final key in _messageKeys(english)) {
      expect(
        _placeholders(arabic[key] as String),
        _placeholders(english[key] as String),
        reason: 'placeholders differ for $key',
      );
    }
  });

  test('no message is left empty', () {
    for (final arb in [english, arabic]) {
      for (final key in _messageKeys(arb)) {
        expect((arb[key] as String).trim(), isNotEmpty, reason: key);
      }
    }
  });
}
