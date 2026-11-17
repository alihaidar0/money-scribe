import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Decides what happens to an error nobody caught.
///
/// With no crash reporting, the only place an error can go is the device log,
/// and the message of an error can hold personal or financial data (text the
/// server sent back, a name, an amount). So the log gets the type only. A debug
/// run keeps Flutter's full report for the developer.
///
/// Call it once the binding exists (`WidgetsFlutterBinding.ensureInitialized`).
void installGlobalErrorHandlers() {
  FlutterError.onError = reportFlutterError;
  WidgetsBinding.instance.platformDispatcher.onError = reportUncaughtError;
}

/// An error thrown inside the framework (a build, a layout, a gesture).
void reportFlutterError(FlutterErrorDetails details) {
  if (kDebugMode) FlutterError.presentError(details);
  debugPrint('Flutter error: ${details.exception.runtimeType}');
}

/// An error thrown outside the framework, for example by a future nobody waits
/// for. `true` says it is handled, so the default report (the whole message) is
/// kept for a debug run only.
bool reportUncaughtError(Object error, StackTrace stackTrace) {
  debugPrint('Uncaught error: ${error.runtimeType}');
  return !kDebugMode;
}
