import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/environment/app_environment.dart';
import 'package:money_scribe/core/environment/app_environment_scope.dart';

void main() {
  testWidgets('gives the environment to the widgets below it', (tester) async {
    AppEnvironment? seen;
    await tester.pumpWidget(
      AppEnvironmentScope(
        environment: AppEnvironment.production,
        child: Builder(
          builder: (context) {
            seen = AppEnvironmentScope.of(context);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(seen, AppEnvironment.production);
  });

  testWidgets('rebuilds the widgets below when the environment changes', (
    tester,
  ) async {
    final seen = <AppEnvironment>[];
    Widget build(AppEnvironment environment) {
      return AppEnvironmentScope(
        environment: environment,
        child: Builder(
          builder: (context) {
            seen.add(AppEnvironmentScope.of(context));
            return const SizedBox();
          },
        ),
      );
    }

    await tester.pumpWidget(build(AppEnvironment.staging));
    await tester.pumpWidget(build(AppEnvironment.production));

    expect(seen, [AppEnvironment.staging, AppEnvironment.production]);
  });
}
