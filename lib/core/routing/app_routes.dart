/// The paths of the app's screens. Kept apart from the router so a screen can
/// link to another without importing the router, which imports every screen.
abstract final class AppRoutes {
  static const overview = '/';
  static const settings = '/settings';
}
