import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/app/router/app_router.dart';

void main() {
  test('the router opens the overview route first', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final router = container.read(appRouterProvider);

    expect(router.routeInformationProvider.value.uri.path, AppRoutes.overview);
  });
}
