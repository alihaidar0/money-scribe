import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/l10n/l10n.dart';

void main() {
  test('the app supports English and Arabic, English first', () {
    expect(AppLocalizations.supportedLocales, const [
      Locale('en'),
      Locale('ar'),
    ]);
  });

  test('English and Arabic load their own strings', () async {
    final english = await AppLocalizations.delegate.load(const Locale('en'));
    final arabic = await AppLocalizations.delegate.load(const Locale('ar'));

    expect(english.overviewTitle, 'Overview');
    expect(arabic.overviewTitle, 'نظرة عامة');
  });

  test('other languages are not supported', () {
    expect(AppLocalizations.delegate.isSupported(const Locale('fr')), isFalse);
  });
}
