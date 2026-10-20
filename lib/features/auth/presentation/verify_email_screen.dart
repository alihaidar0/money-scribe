import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/routing/app_routes.dart';
import 'package:money_scribe/features/auth/domain/auth_repository.dart';
import 'package:money_scribe/features/auth/presentation/widgets/code_entry_page.dart';

/// How the Verify your email screen was reached, because the words differ.
enum VerifyEmailOrigin {
  /// After creating an account. A code may or may not have been sent: the
  /// answer is the same whether the address is new, pending or already
  /// registered, so the screen adds a hint for the person who has an account.
  registration,

  /// After signing in with an address that was never verified. Nothing was
  /// sent, so the person asks for a code.
  signIn,
}

/// AUTH-4, AUTH-4b and AUTH-4c: type the code sent to a new account's email.
class VerifyEmailScreen extends StatelessWidget {
  const new({this.origin = VerifyEmailOrigin.registration, super.key});

  final VerifyEmailOrigin origin;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fromRegistration = origin == VerifyEmailOrigin.registration;

    return CodeEntryPage(
      purpose: CodePurpose.verifyEmail,
      title: l10n.verifyEmailTitle,
      actionLabel: l10n.verifyAction,
      codeWasSent: fromRegistration,
      showAccountHint: fromRegistration,
      onVerified: (context) => context.go(AppRoutes.emailVerified),
    );
  }
}
