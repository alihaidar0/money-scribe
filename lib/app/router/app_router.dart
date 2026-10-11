import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:money_scribe/app/demo/demo_panel_screen.dart';
import 'package:money_scribe/app/shell/app_shell.dart';
import 'package:money_scribe/core/routing/app_routes.dart';
import 'package:money_scribe/features/auth/domain/auth_repository.dart';
import 'package:money_scribe/features/auth/presentation/app_lock_screen.dart';
import 'package:money_scribe/features/auth/presentation/create_pin_screen.dart';
import 'package:money_scribe/features/auth/presentation/email_verified_screen.dart';
import 'package:money_scribe/features/auth/presentation/forgot_password_screen.dart';
import 'package:money_scribe/features/auth/presentation/new_password_screen.dart';
import 'package:money_scribe/features/auth/presentation/password_changed_screen.dart';
import 'package:money_scribe/features/auth/presentation/pin_entry_screen.dart';
import 'package:money_scribe/features/auth/presentation/register_screen.dart';
import 'package:money_scribe/features/auth/presentation/reset_code_screen.dart';
import 'package:money_scribe/features/auth/presentation/sign_in_screen.dart';
import 'package:money_scribe/features/auth/presentation/verify_email_screen.dart';
import 'package:money_scribe/features/auth/presentation/welcome_screen.dart';
import 'package:money_scribe/features/debts/presentation/debts_screen.dart';
import 'package:money_scribe/features/overview/presentation/overview_screen.dart';
import 'package:money_scribe/features/reports/presentation/reports_screen.dart';
import 'package:money_scribe/features/salary/presentation/fixed_items_screen.dart';
import 'package:money_scribe/features/salary/presentation/salary_screen.dart';
import 'package:money_scribe/features/settings/presentation/pay_setup_screen.dart';
import 'package:money_scribe/features/settings/presentation/settings_screen.dart';
import 'package:money_scribe/features/transactions/presentation/add_transaction_screen.dart';
import 'package:money_scribe/features/transactions/presentation/transactions_screen.dart';

/// The routes of the app. The caller owns the router and disposes it.
///
/// A signed-out person is sent to the Welcome screen, and a signed-in one
/// leaves the sign-in screens for the Overview. [refreshListenable] tells the
/// router to check again when the person signs in or out.
GoRouter createAppRouter({
  required AuthRepository auth,
  required Listenable refreshListenable,
}) {
  return GoRouter(
    refreshListenable: refreshListenable,
    redirect: (context, state) => _redirect(auth, state.uri.path),
    routes: [
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.signIn,
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.verifyEmail,
        builder: (context, state) => const VerifyEmailScreen(),
      ),
      GoRoute(
        path: AppRoutes.emailVerified,
        builder: (context, state) => const EmailVerifiedScreen(),
      ),
      GoRoute(
        path: AppRoutes.paySetup,
        builder: (context, state) => const PaySetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.resetCode,
        builder: (context, state) => const ResetCodeScreen(),
      ),
      GoRoute(
        path: AppRoutes.newPassword,
        builder: (context, state) => const NewPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.passwordChanged,
        builder: (context, state) => const PasswordChangedScreen(),
      ),
      GoRoute(
        path: AppRoutes.appLock,
        builder: (context, state) => const AppLockScreen(),
      ),
      GoRoute(
        path: AppRoutes.pinEntry,
        builder: (context, state) => const PinEntryScreen(),
      ),
      GoRoute(
        path: AppRoutes.createPin,
        builder: (context, state) => const CreatePinScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.addTransaction,
        builder: (context, state) => const AddTransactionScreen(),
      ),
      GoRoute(
        path: AppRoutes.fixedItems,
        builder: (context, state) => const FixedItemsScreen(),
      ),
      GoRoute(
        path: AppRoutes.demo,
        builder: (context, state) => const DemoPanelScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.overview,
                builder: (context, state) => const OverviewScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.salary,
                builder: (context, state) => const SalaryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.transactions,
                builder: (context, state) => const TransactionsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.debts,
                builder: (context, state) => const DebtsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.reports,
                builder: (context, state) => const ReportsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

String? _redirect(AuthRepository auth, String path) {
  if (!auth.isSignedIn) {
    final open =
        AppRoutes.withoutSignIn.contains(path) || path == AppRoutes.demo;
    return open ? null : AppRoutes.welcome;
  }
  return AppRoutes.signedOutOnly.contains(path) ? AppRoutes.overview : null;
}
