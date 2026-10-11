import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/routing/app_routes.dart';
import 'package:money_scribe/features/auth/domain/auth_repository.dart';
import 'package:money_scribe/features/auth/presentation/widgets/code_entry_page.dart';

/// AUTH-8 and AUTH-8b: type the code sent to reset the password.
class ResetCodeScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return CodeEntryPage(
      purpose: CodePurpose.resetPassword,
      title: l10n.enterCodeTitle,
      actionLabel: l10n.continueAction,
      onVerified: (context) => context.push(AppRoutes.newPassword),
    );
  }
}
