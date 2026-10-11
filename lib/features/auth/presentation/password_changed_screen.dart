import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/routing/app_routes.dart';
import 'package:money_scribe/features/auth/presentation/widgets/confirmation_page.dart';

/// AUTH-10: the password was changed. It has no state and no data, so it
/// needs no Bloc.
class PasswordChangedScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ConfirmationPage(
      title: l10n.passwordChangedTitle,
      message: l10n.passwordChangedMessage,
      actionLabel: l10n.signIn,
      onAction: () => context.go(AppRoutes.signIn),
    );
  }
}
