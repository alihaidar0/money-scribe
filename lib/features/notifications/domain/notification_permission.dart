/// Whether the app may show notifications.
enum NotificationPermission {
  /// Notifications are allowed.
  granted,

  /// Notifications are not allowed yet; the app can still ask.
  notGranted,

  /// The user refused and the system will not ask again; notifications can only
  /// be turned on in the system settings.
  blocked,
}
