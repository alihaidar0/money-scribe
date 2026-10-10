import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:money_scribe/features/overview/presentation/overview_screen.dart';

abstract final class AppRoutes {
  static const overview = '/';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: AppRoutes.overview,
        builder: (context, state) => const OverviewScreen(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
