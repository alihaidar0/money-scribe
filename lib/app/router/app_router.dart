import 'package:go_router/go_router.dart';
import 'package:money_scribe/core/routing/app_routes.dart';
import 'package:money_scribe/features/overview/presentation/overview_screen.dart';
import 'package:money_scribe/features/settings/presentation/settings_screen.dart';

/// The routes of the app. The caller owns the router and disposes it.
GoRouter createAppRouter() {
  return GoRouter(
    routes: [
      GoRoute(
        path: AppRoutes.overview,
        builder: (context, state) => const OverviewScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
}
