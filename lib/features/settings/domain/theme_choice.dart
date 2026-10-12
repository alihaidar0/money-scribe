/// The colours the app is shown in: follow the device, or always light or
/// always dark.
enum ThemeChoice {
  system,
  light,
  dark;

  /// The choice for a stored name; anything unknown follows the device.
  static ThemeChoice fromName(String? name) {
    return values.firstWhere(
      (choice) => choice.name == name,
      orElse: () => ThemeChoice.system,
    );
  }
}
