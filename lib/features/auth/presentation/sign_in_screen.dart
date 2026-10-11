import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:money_scribe/core/formatting/countdown_format.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/routing/app_routes.dart';
import 'package:money_scribe/core/time/ticker.dart';
import 'package:money_scribe/core/widgets/app_text_field.dart';
import 'package:money_scribe/core/widgets/button_spinner.dart';
import 'package:money_scribe/core/widgets/flow_page.dart';
import 'package:money_scribe/core/widgets/message_banner.dart';
import 'package:money_scribe/core/widgets/password_field.dart';
import 'package:money_scribe/core/widgets/state_view.dart';
import 'package:money_scribe/features/auth/bloc/sign_in_bloc.dart';
import 'package:money_scribe/features/auth/domain/auth_repository.dart';

/// AUTH-2, AUTH-2b and AUTH-2c: sign in with an email and a password.
class SignInScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SignInBloc(
        repository: context.read<AuthRepository>(),
        ticker: context.read<Ticker>(),
      )..add(const SignInStarted()),
      child: const _SignInView(),
    );
  }
}

class _SignInView extends StatefulWidget {
  const new();

  @override
  State<_SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends State<_SignInView> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    context.read<SignInBloc>().add(
      SignInSubmitted(email: _email.text.trim(), password: _password.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return BlocConsumer<SignInBloc, SignInState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == SignInStatus.success,
      listener: (context, state) => context.go(AppRoutes.overview),
      builder: (context, state) {
        final isLocked = state.status == SignInStatus.locked;
        final isBusy = state.status == SignInStatus.submitting;
        final canEdit = !isLocked && !isBusy;
        final hasWrongCredentials =
            state.status == SignInStatus.wrongCredentials;

        return FlowPage(
          failure: switch (state.status) {
            SignInStatus.noConnection => FailureKind.noConnection,
            SignInStatus.failure => FailureKind.error,
            _ => null,
          },
          onRetry: _submit,
          content: [
            Semantics(
              header: true,
              child: Text(l10n.signIn, style: theme.textTheme.headlineMedium),
            ),
            const SizedBox(height: 8),
            Text(l10n.signInWelcomeBack, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 24),
            if (hasWrongCredentials) ...[
              MessageBanner(
                icon: Icons.error_outline,
                text: l10n.signInWrongCredentials,
              ),
              const SizedBox(height: 16),
            ],
            if (isLocked) ...[
              MessageBanner(
                icon: Icons.lock_outline,
                text: l10n.signInLocked(
                  time: formatCountdown(state.lockSecondsLeft),
                ),
              ),
              const SizedBox(height: 16),
            ],
            AppTextField(
              controller: _email,
              label: l10n.emailLabel,
              enabled: canEdit,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              textDirection: TextDirection.ltr,
              showErrorOutline: hasWrongCredentials,
            ),
            const SizedBox(height: 16),
            PasswordField(
              controller: _password,
              label: l10n.passwordLabel,
              enabled: canEdit,
              showErrorOutline: hasWrongCredentials,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                if (canEdit) _submit();
              },
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: () => context.push(AppRoutes.forgotPassword),
                child: Text(l10n.forgotPasswordLink),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: canEdit ? _submit : null,
              child: isBusy ? const ButtonSpinner() : Text(l10n.signIn),
            ),
          ],
          bottomChildren: [
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(l10n.newToApp, style: theme.textTheme.bodyMedium),
                TextButton(
                  onPressed: () => context.pushReplacement(AppRoutes.register),
                  child: Text(l10n.createAccount),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
