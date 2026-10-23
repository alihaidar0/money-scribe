import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/routing/app_routes.dart';

void main() {
  group('where an unlocked app goes', () {
    test('back to the screen the person was on', () {
      expect(AppRoutes.returnTo('/debts'), '/debts');
      expect(
        AppRoutes.returnTo('/transactions?category=food&month=2026-10'),
        '/transactions?category=food&month=2026-10',
      );
      expect(AppRoutes.returnTo('/settings/account'), '/settings/account');
    });

    test('the Overview when there is nothing to go back to', () {
      expect(AppRoutes.returnTo(null), AppRoutes.overview);
      expect(AppRoutes.returnTo(''), AppRoutes.overview);
    });

    test('never to another site, nor to something that is not a screen', () {
      for (final from in [
        'https://example.com/steal',
        '//example.com',
        'javascript:alert(1)',
        'debts',
      ]) {
        expect(AppRoutes.returnTo(from), AppRoutes.overview, reason: from);
      }
    });

    test('never back to the lock screen, nor to a sign-in screen', () {
      for (final from in [
        AppRoutes.appLock,
        '${AppRoutes.pinEntry}?from=%2Fdebts',
        AppRoutes.signIn,
        AppRoutes.welcome,
        AppRoutes.forgotPassword,
      ]) {
        expect(AppRoutes.returnTo(from), AppRoutes.overview, reason: from);
      }
    });

    test('the lock screen address carries where to go back to', () {
      final address = AppRoutes.lockedAt('/debts/42?repay=1');

      expect(Uri.parse(address).path, AppRoutes.appLock);
      expect(Uri.parse(address).queryParameters['from'], '/debts/42?repay=1');
      expect(
        Uri.parse(AppRoutes.pinEntryFor('/debts')).queryParameters['from'],
        '/debts',
      );
      expect(AppRoutes.pinEntryFor(null), AppRoutes.pinEntry);
    });
  });
}
