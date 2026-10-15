import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/routing/app_routes.dart';
import 'package:money_scribe/features/auth/presentation/widgets/confirmation_page.dart';

/// AUTH-5: the email address was verified. It has no state and no data, so it
/// needs no Bloc.
class EmailVerifiedScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ConfirmationPage(
      title: l10n.emailVerifiedTitle,
      message: l10n.emailVerifiedMessage,
      actionLabel: l10n.continueAction,
      onAction: () => context.go(AppRoutes.paySetup),
    );
  }
}
