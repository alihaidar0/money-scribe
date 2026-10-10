import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/features/settings/domain/app_language.dart';

void main() {
  test('the system language forces no locale', () {
    expect(AppLanguage.system.locale, isNull);
  });

  test('English and Arabic force their own locale', () {
    expect(AppLanguage.english.locale, const Locale('en'));
    expect(AppLanguage.arabic.locale, const Locale('ar'));
  });

  test('a stored language code maps back to its language', () {
    expect(AppLanguage.fromLanguageCode('en'), AppLanguage.english);
    expect(AppLanguage.fromLanguageCode('ar'), AppLanguage.arabic);
  });

  test('a missing or unknown language code follows the system', () {
    expect(AppLanguage.fromLanguageCode(null), AppLanguage.system);
    expect(AppLanguage.fromLanguageCode('fr'), AppLanguage.system);
  });
}
