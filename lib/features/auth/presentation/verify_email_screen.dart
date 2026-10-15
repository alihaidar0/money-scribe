import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/routing/app_routes.dart';
import 'package:money_scribe/features/auth/domain/auth_repository.dart';
import 'package:money_scribe/features/auth/presentation/widgets/code_entry_page.dart';

/// AUTH-4, AUTH-4b and AUTH-4c: type the code sent to a new account's email.
class VerifyEmailScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return CodeEntryPage(
      purpose: CodePurpose.verifyEmail,
      title: l10n.verifyEmailTitle,
      actionLabel: l10n.verifyAction,
      onVerified: (context) => context.go(AppRoutes.emailVerified),
    );
  }
}
