import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:money_scribe/core/formatting/countdown_format.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/routing/app_routes.dart';
import 'package:money_scribe/core/time/ticker.dart';
import 'package:money_scribe/core/widgets/app_text_field.dart';
import 'package:money_scribe/core/widgets/password_field.dart';
import 'package:money_scribe/core/widgets/pinned_button_bar.dart';
import 'package:money_scribe/core/widgets/state_view.dart';
import 'package:money_scribe/features/auth/bloc/change_email_bloc.dart';
import 'package:money_scribe/features/auth/domain/auth_exception.dart';
import 'package:money_scribe/features/auth/domain/auth_repository.dart';
import 'package:money_scribe/features/auth/presentation/email_change_outcome.dart';

/// ST-12: change the email: the new address and the current password. A code
/// is sent to the new address and typed on the next screen (ST-12b); the
/// address of the account changes only then. The screen answers how the change
/// ended ([EmailChangeOutcome]), or nothing when the person went back.
class ChangeEmailScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ChangeEmailBloc(
        repository: context.read<AuthRepository>(),
        ticker: context.read<Ticker>(),
      ),
      child: const _ChangeEmailView(),
    );
  }
}

class _ChangeEmailView extends StatefulWidget {
  const new();

  @override
  State<_ChangeEmailView> createState() => _ChangeEmailViewState();
}

class _ChangeEmailViewState extends State<_ChangeEmailView> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _edited([String? _]) {
    context.read<ChangeEmailBloc>().add(
      ChangeEmailEdited(email: _email.text, password: _password.text),
    );
  }

  void _submit() =>
      context.read<ChangeEmailBloc>().add(const ChangeEmailSubmitted());

  /// Opens the code screen, and ends this one too when the change is over. The
  /// password is not kept: coming back to this screen asks for it again.
  Future<void> _openCodeScreen() async {
    _password.clear();
    _edited();
    final outcome = await context.push<EmailChangeOutcome>(
      AppRoutes.changeEmailCode,
    );
    if (outcome != null && mounted) context.pop(outcome);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return BlocConsumer<ChangeEmailBloc, ChangeEmailState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == ChangeEmailStatus.sent,
      listener: (context, state) => _openCodeScreen(),
      builder: (context, state) {
        final failure = switch (state.status) {
          ChangeEmailStatus.unavailable => FailureKind.unavailable,
          ChangeEmailStatus.noConnection => FailureKind.noConnection,
          ChangeEmailStatus.failure => FailureKind.error,
          _ => null,
        };
        final isBusy = state.status == ChangeEmailStatus.sending;
        final isWaiting = state.status == ChangeEmailStatus.waiting;
        final emailError = state.status == ChangeEmailStatus.rejected
            ? switch (state.issue) {
                EmailIssue.unchanged => l10n.changeEmailUnchanged,
                EmailIssue.taken => l10n.changeEmailTaken,
                EmailIssue.invalid || null => l10n.registerEmailInvalid,
              }
            : null;

        return Scaffold(
          appBar: AppBar(title: Text(l10n.changeEmail)),
          body: Stack(
            fit: StackFit.expand,
            children: [
              // The form keeps what was typed while the failure is shown.
              Offstage(
                offstage: failure != null,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.changeEmailMessage,
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 24),
                      AppTextField(
                        controller: _email,
                        label: l10n.newEmailLabel,
                        enabled: !isBusy,
                        errorText: emailError,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        textDirection: TextDirection.ltr,
                        onChanged: _edited,
                      ),
                      const SizedBox(height: 16),
                      PasswordField(
                        controller: _password,
                        label: l10n.currentPasswordLabel,
                        enabled: !isBusy,
                        errorText:
                            state.status == ChangeEmailStatus.wrongPassword
                            ? l10n.changePasswordWrongCurrent
                            : null,
                        textInputAction: TextInputAction.done,
                        onChanged: _edited,
                        onSubmitted: (_) {
                          if (state.canSend && !isBusy && !isWaiting) _submit();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              if (failure != null)
                Positioned.fill(
                  child: FailureView(kind: failure, onRetry: _submit),
                ),
            ],
          ),
          bottomNavigationBar: failure == null
              ? PinnedButtonBar(
                  // The server asked to wait: the button counts down.
                  label: isWaiting
                      ? l10n.tryAgainIn(
                          time: formatCountdown(state.waitSecondsLeft),
                        )
                      : l10n.sendCode,
                  isBusy: isBusy,
                  onPressed: state.canSend && !isBusy && !isWaiting
                      ? _submit
                      : null,
                )
              : null,
        );
      },
    );
  }
}
