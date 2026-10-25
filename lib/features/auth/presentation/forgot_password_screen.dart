import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:money_scribe/core/formatting/countdown_format.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/routing/app_routes.dart';
import 'package:money_scribe/core/routing/navigation_extensions.dart';
import 'package:money_scribe/core/time/ticker.dart';
import 'package:money_scribe/core/widgets/app_text_field.dart';
import 'package:money_scribe/core/widgets/button_spinner.dart';
import 'package:money_scribe/core/widgets/flow_page.dart';
import 'package:money_scribe/core/widgets/state_view.dart';
import 'package:money_scribe/features/auth/bloc/forgot_password_bloc.dart';
import 'package:money_scribe/features/auth/domain/auth_repository.dart';

/// AUTH-7: ask for a code to reset the password.
class ForgotPasswordScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ForgotPasswordBloc(
        repository: context.read<AuthRepository>(),
        ticker: context.read<Ticker>(),
      ),
      child: const _ForgotPasswordView(),
    );
  }
}

class _ForgotPasswordView extends StatefulWidget {
  const new();

  @override
  State<_ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<_ForgotPasswordView> {
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _submit() {
    context.read<ForgotPasswordBloc>().add(
      ForgotPasswordSubmitted(_email.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return BlocConsumer<ForgotPasswordBloc, ForgotPasswordState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == ForgotPasswordStatus.success,
      listener: (context, state) => context.push(AppRoutes.resetCode),
      builder: (context, state) {
        final isBusy = state.status == ForgotPasswordStatus.submitting;
        final isWaiting = state.status == ForgotPasswordStatus.waiting;

        return FlowPage(
          failure: switch (state.status) {
            ForgotPasswordStatus.unavailable => FailureKind.unavailable,
            ForgotPasswordStatus.noConnection => FailureKind.noConnection,
            ForgotPasswordStatus.failure => FailureKind.error,
            _ => null,
          },
          onRetry: _submit,
          content: [
            Semantics(
              header: true,
              child: Text(
                l10n.forgotPasswordLink,
                style: theme.textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: 8),
            Text(l10n.forgotPasswordMessage, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 24),
            AppTextField(
              controller: _email,
              label: l10n.emailLabel,
              enabled: !isBusy,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.email],
              textDirection: TextDirection.ltr,
              onSubmitted: (_) {
                if (!isBusy && !isWaiting) _submit();
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: isBusy || isWaiting ? null : _submit,
              child: switch (state.status) {
                ForgotPasswordStatus.submitting => const ButtonSpinner(),
                // The server asked to wait: the button counts down.
                ForgotPasswordStatus.waiting => Text(
                  l10n.tryAgainIn(time: formatCountdown(state.waitSecondsLeft)),
                ),
                _ => Text(l10n.sendCode),
              },
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.popOrGo(AppRoutes.signIn),
              child: Text(l10n.backToSignIn),
            ),
          ],
        );
      },
    );
  }
}
