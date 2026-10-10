import 'package:flutter/services.dart' show appFlavor;

/// The environment a build is made for: `staging` (the `develop` branch) or
/// `production` (the `main` branch). See `docs/environments.md`.
enum AppEnvironment {
  staging,
  production;

  /// The environment of this build.
  static final AppEnvironment current = resolve(
    define: const String.fromEnvironment('APP_ENV'),
    flavor: appFlavor,
  );

  /// Picks the environment from the `APP_ENV` value (`--dart-define`, which CI
  /// passes to every build, web builds included) or else from the Flutter
  /// flavor (`appFlavor`). Without either, or with an unknown name, it is
  /// [staging], so a misconfigured build never counts as production.
  static AppEnvironment resolve({
    required String? define,
    required String? flavor,
  }) {
    final name = (define != null && define.isNotEmpty) ? define : flavor;
    return values.firstWhere(
      (environment) => environment.name == name,
      orElse: () => AppEnvironment.staging,
    );
  }

  bool get isProduction => this == AppEnvironment.production;
}
