import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/app/global_error_handlers.dart';

void main() {
  late List<String> logs;
  late List<FlutterErrorDetails> presented;
  late DebugPrintCallback originalDebugPrint;
  late FlutterExceptionHandler? originalPresentError;

  setUp(() {
    logs = [];
    presented = [];
    originalDebugPrint = debugPrint;
    originalPresentError = FlutterError.presentError;
    debugPrint = (message, {wrapWidth}) => logs.add(message ?? '');
    FlutterError.presentError = presented.add;
  });

  tearDown(() {
    debugPrint = originalDebugPrint;
    FlutterError.presentError = originalPresentError!;
  });

  test('a framework error is logged by its type, never its message', () {
    reportFlutterError(
      FlutterErrorDetails(exception: Exception('secret detail')),
    );

    expect(logs, ['Flutter error: _Exception']);
    expect(logs.join(), isNot(contains('secret')));
  });

  test('a debug run still gets the full report of a framework error', () {
    final details = FlutterErrorDetails(exception: Exception('secret detail'));

    reportFlutterError(details);

    expect(presented, [details]);
  });

  test('an uncaught error is logged by its type, never its message', () {
    reportUncaughtError(StateError('secret detail'), StackTrace.empty);

    expect(logs, ['Uncaught error: StateError']);
    expect(logs.join(), isNot(contains('secret')));
  });

  test('a debug run leaves an uncaught error to the default report', () {
    final handled = reportUncaughtError(Exception('x'), StackTrace.empty);

    expect(handled, isFalse);
  });
}
