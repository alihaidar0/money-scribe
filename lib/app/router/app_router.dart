import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:money_scribe/features/overview/presentation/overview_screen.dart';
import 'package:money_scribe/features/settings/presentation/settings_screen.dart';

abstract final class AppRoutes {
  static const overview = '/';
  static const settings = '/settings';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
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
  ref.onDispose(router.dispose);
  return router;
});
