import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/app/router/app_router.dart';
import 'package:money_scribe/core/routing/app_routes.dart';

void main() {
  test('the router opens the overview route first', () {
    final router = createAppRouter();
    addTearDown(router.dispose);

    expect(router.routeInformationProvider.value.uri.path, AppRoutes.overview);
  });
}
