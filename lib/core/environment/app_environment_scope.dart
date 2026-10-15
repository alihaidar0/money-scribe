import 'package:flutter/widgets.dart';
import 'package:money_scribe/core/environment/app_environment.dart';

/// Makes the environment of this build available to every widget below it.
class AppEnvironmentScope extends InheritedWidget {
  const new({required this.environment, required super.child, super.key});

  final AppEnvironment environment;

  /// The environment of the nearest scope above [context].
  static AppEnvironment of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppEnvironmentScope>();
    assert(scope != null, 'No AppEnvironmentScope above this context.');
    return scope!.environment;
  }

  @override
  bool updateShouldNotify(AppEnvironmentScope oldWidget) {
    return environment != oldWidget.environment;
  }
}
