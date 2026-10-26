import 'package:flutter/widgets.dart';
import 'package:money_scribe/core/network/last_failure.dart';

/// Gives the screens below it the [LastFailure] of the app. A screen built
/// without one (a test, a build with no server) has nothing to show.
class LastFailureScope extends InheritedWidget {
  const new({required this.failure, required super.child, super.key});

  final LastFailure failure;

  /// The failure note of the app, or `null` when there is none.
  static LastFailure? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<LastFailureScope>()
        ?.failure;
  }

  @override
  bool updateShouldNotify(LastFailureScope oldWidget) =>
      failure != oldWidget.failure;
}
