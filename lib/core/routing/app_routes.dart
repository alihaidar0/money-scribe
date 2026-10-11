/// The paths of the app's screens. Kept apart from the router so a screen can
/// link to another without importing the router, which imports every screen.
abstract final class AppRoutes {
  // Authentication and first start.
  static const welcome = '/welcome';
  static const signIn = '/sign-in';
  static const register = '/register';
  static const verifyEmail = '/verify-email';
  static const emailVerified = '/email-verified';
  static const paySetup = '/pay-setup';
  static const forgotPassword = '/forgot-password';
  static const resetCode = '/reset-code';
  static const newPassword = '/new-password';
  static const passwordChanged = '/password-changed';
  static const appLock = '/app-lock';
  static const pinEntry = '/pin-entry';
  static const createPin = '/create-pin';

  // The five top-level screens, in the order of the navigation bar.
  static const overview = '/';
  static const salary = '/salary';
  static const transactions = '/transactions';
  static const debts = '/debts';
  static const reports = '/reports';

  // Secondary screens.
  static const settings = '/settings';

  /// The demo panel of staging builds. It goes away with the fake data.
  static const demo = '/demo';

  /// The screens a signed-in person has no reason to see: they lead to the
  /// app, so opening one of them goes to the Overview instead.
  static const List<String> signedOutOnly = [
    welcome,
    signIn,
    register,
    forgotPassword,
    resetCode,
    newPassword,
    passwordChanged,
  ];

  /// The screens that need no sign-in. Everything else sends a signed-out
  /// person to the Welcome screen. Verifying the email is in this list but not
  /// in [signedOutOnly]: a correct code signs the person in while the screen
  /// is still open, and the next screen follows from there.
  static const List<String> withoutSignIn = [
    ...signedOutOnly,
    verifyEmail,
    appLock,
    pinEntry,
  ];
}
