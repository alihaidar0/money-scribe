/// The version of the app, as the person reads it in the Settings. Builds can
/// pass the real one with `--dart-define=APP_VERSION=<version>`; without it
/// this is the version of `pubspec.yaml`, which a test keeps in step.
const appVersion = String.fromEnvironment('APP_VERSION', defaultValue: '0.1.0');
