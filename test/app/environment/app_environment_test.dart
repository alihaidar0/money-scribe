import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/app/environment/app_environment.dart';

void main() {
  group('resolve', () {
    test('uses the APP_ENV value first', () {
      expect(
        AppEnvironment.resolve(define: 'production', flavor: 'staging'),
        AppEnvironment.production,
      );
      expect(
        AppEnvironment.resolve(define: 'staging', flavor: 'production'),
        AppEnvironment.staging,
      );
    });

    test('falls back to the flavor when APP_ENV is empty or missing', () {
      expect(
        AppEnvironment.resolve(define: '', flavor: 'production'),
        AppEnvironment.production,
      );
      expect(
        AppEnvironment.resolve(define: null, flavor: 'production'),
        AppEnvironment.production,
      );
    });

    test('defaults to staging without a value', () {
      expect(
        AppEnvironment.resolve(define: null, flavor: null),
        AppEnvironment.staging,
      );
    });

    test('never counts an unknown name as production', () {
      expect(
        AppEnvironment.resolve(define: 'prod', flavor: null),
        AppEnvironment.staging,
      );
      expect(
        AppEnvironment.resolve(define: null, flavor: 'Production'),
        AppEnvironment.staging,
      );
    });
  });

  test('only production is production', () {
    expect(AppEnvironment.production.isProduction, isTrue);
    expect(AppEnvironment.staging.isProduction, isFalse);
  });

  test('a plain test run is the staging environment', () {
    expect(AppEnvironment.current, AppEnvironment.staging);
  });
}
