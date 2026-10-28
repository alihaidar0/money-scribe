import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:money_scribe/core/challenge/challenge_view_factory.dart';
import 'package:money_scribe/core/formatting/countdown_format.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/routing/app_routes.dart';
import 'package:money_scribe/core/routing/navigation_extensions.dart';
import 'package:money_scribe/core/time/ticker.dart';
import 'package:money_scribe/core/widgets/app_text_field.dart';
import 'package:money_scribe/core/widgets/button_spinner.dart';
import 'package:money_scribe/core/widgets/flow_page.dart';
import 'package:money_scribe/core/widgets/icon_circle.dart';
import 'package:money_scribe/core/widgets/message_banner.dart';
import 'package:money_scribe/core/widgets/password_field.dart';
import 'package:money_scribe/core/widgets/state_view.dart';
import 'package:money_scribe/features/auth/bloc/sign_in_bloc.dart';
import 'package:money_scribe/features/auth/domain/auth_repository.dart';
import 'package:money_scribe/features/auth/domain/device_key.dart';
import 'package:money_scribe/features/auth/domain/device_key_repository.dart';
import 'package:money_scribe/features/auth/domain/sign_out_reason.dart';
import 'package:money_scribe/features/auth/presentation/sign_in_challenge_sheet.dart';
import 'package:money_scribe/features/auth/presentation/verify_email_screen.dart';

/// AUTH-2, AUTH-2b, AUTH-2c and AUTH-2d: sign in with an email and a password.
/// The password is sent as typed and never checked against a policy: only the
/// server knows whether it is right. A phone that has a fingerprint key offers
/// to sign in with it first, with a way to use another account. When the
/// server signed the device out (too many devices, for example), a notice says
/// why.
class SignInScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SignInBloc(
        repository: context.read<AuthRepository>(),
        deviceKeys: context.read<DeviceKeyRepository>(),
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

  void _submit({String? challengeToken}) {
    context.read<SignInBloc>().add(
      SignInSubmitted(
        email: _email.text.trim(),
        password: _password.text,
        challengeToken: challengeToken,
      ),
    );
  }

  void _signInWithFingerprint() {
    context.read<SignInBloc>().add(
      SignInFingerprintRequested(prompt: context.l10n.signInFingerprintReason),
    );
  }

  /// Shows the bot challenge and, once it is solved, sends the same sign-in
  /// again with its token: the person solved it to sign in, so this is the
  /// sign-in they asked for, sent once.
  Future<void> _askChallenge({required bool rejected}) async {
    final bloc = context.read<SignInBloc>();
    final token = await showSignInChallengeSheet(
      context,
      factory: context.read<ChallengeViewFactory>(),
      rejected: rejected,
    );
    if (!mounted) return;
    if (token == null) {
      bloc.add(const SignInChallengeDismissed());
    } else {
      _submit(challengeToken: token);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return BlocConsumer<SignInBloc, SignInState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          (current.status == SignInStatus.success ||
              current.status == SignInStatus.emailNotVerified ||
              current.status == SignInStatus.challengeRequired ||
              current.status == SignInStatus.challengeRejected),
      listener: (context, state) {
        if (state.status == SignInStatus.success) {
          context.go(AppRoutes.overview);
        } else if (state.status == SignInStatus.challengeRequired ||
            state.status == SignInStatus.challengeRejected) {
          unawaited(
            _askChallenge(
              rejected: state.status == SignInStatus.challengeRejected,
            ),
          );
        } else {
          // The password was right: the address still has to be verified.
          unawaited(
            context.push<void>(
              AppRoutes.verifyEmail,
              extra: VerifyEmailOrigin.signIn,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLocked = state.status == SignInStatus.locked;
        final fingerprintBusy =
            state.status == SignInStatus.fingerprintSubmitting;
        final isBusy =
            state.status == SignInStatus.submitting || fingerprintBusy;
        final isChallenged =
            state.status == SignInStatus.challengeRequired ||
            state.status == SignInStatus.challengeRejected;
        final canEdit = !isLocked && !isBusy && !isChallenged;
        final hasWrongCredentials =
            state.status == SignInStatus.wrongCredentials;
        final emailNotRegistered =
            state.status == SignInStatus.emailNotRegistered;
        final wrongPassword = state.status == SignInStatus.wrongPassword;
        final account = state.fingerprintAccount;
        final signOutReason = state.signOutReason;
        final fingerprintMessage = switch (state.status) {
          SignInStatus.fingerprintUnavailable =>
            l10n.signInFingerprintUnavailable,
          SignInStatus.fingerprintRefused => l10n.signInFingerprintRefused,
          SignInStatus.fingerprintKeyChanged =>
            l10n.signInFingerprintKeyChanged,
          _ => null,
        };

        return FlowPage(
          failure: switch (state.status) {
            SignInStatus.noConnection => FailureKind.noConnection,
            SignInStatus.unavailable => FailureKind.unavailable,
            SignInStatus.failure => FailureKind.error,
            _ => null,
          },
          onRetry: state.viaFingerprint ? _signInWithFingerprint : _submit,
          // The server's sign-out opens this page on its own: back is Welcome.
          onBack: () => context.popOrGo(AppRoutes.welcome),
          content: [
            Semantics(
              header: true,
              child: Text(l10n.signIn, style: theme.textTheme.headlineMedium),
            ),
            const SizedBox(height: 8),
            Text(l10n.signInWelcomeBack, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 24),
            if (signOutReason != null) ...[
              MessageBanner(
                icon: _signOutIcon(signOutReason),
                text: _signOutText(l10n, signOutReason),
                tone: BannerTone.info,
              ),
              const SizedBox(height: 16),
            ],
            if (fingerprintMessage != null) ...[
              MessageBanner(
                icon: LucideIcons.circleAlert,
                text: fingerprintMessage,
              ),
              const SizedBox(height: 16),
            ],
            if (hasWrongCredentials) ...[
              MessageBanner(
                icon: LucideIcons.circleAlert,
                text: l10n.signInWrongCredentials,
              ),
              const SizedBox(height: 16),
            ],
            if (isLocked) ...[
              MessageBanner(
                icon: LucideIcons.lock,
                text: l10n.signInLocked(
                  time: formatCountdown(state.lockSecondsLeft),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (state.offersFingerprint && account != null) ...[
              _FingerprintCard(
                account: account,
                busy: fingerprintBusy,
                locked: isLocked,
                onSignIn: _signInWithFingerprint,
                onOtherAccount: () => context.read<SignInBloc>().add(
                  const SignInOtherAccountChosen(),
                ),
              ),
            ] else ...[
              AppTextField(
                controller: _email,
                label: l10n.emailLabel,
                enabled: canEdit,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                textDirection: TextDirection.ltr,
                showErrorOutline: hasWrongCredentials,
                errorText: emailNotRegistered
                    ? l10n.signInEmailNotRegistered
                    : null,
                onChanged: (_) =>
                    context.read<SignInBloc>().add(const SignInEmailEdited()),
              ),
              const SizedBox(height: 16),
              PasswordField(
                controller: _password,
                label: l10n.passwordLabel,
                enabled: canEdit,
                showErrorOutline: hasWrongCredentials,
                errorText: wrongPassword ? l10n.signInWrongPassword : null,
                onChanged: (_) => context.read<SignInBloc>().add(
                  const SignInPasswordEdited(),
                ),
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
                child: state.status == SignInStatus.submitting
                    ? const ButtonSpinner()
                    : Text(l10n.signIn),
              ),
            ],
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

IconData _signOutIcon(SignOutReason reason) => switch (reason) {
  SignOutReason.tooManyDevices => LucideIcons.monitorSmartphone,
  SignOutReason.endedElsewhere => LucideIcons.logOutDir,
  SignOutReason.passwordChanged => LucideIcons.lockKeyhole,
  SignOutReason.emailChanged => LucideIcons.atSign,
  SignOutReason.security => LucideIcons.shield,
  SignOutReason.expired => LucideIcons.clock,
  SignOutReason.other => LucideIcons.logOutDir,
};

String _signOutText(AppLocalizations l10n, SignOutReason reason) =>
    switch (reason) {
      SignOutReason.tooManyDevices => l10n.signedOutTooManyDevices,
      SignOutReason.endedElsewhere => l10n.signedOutElsewhere,
      SignOutReason.passwordChanged => l10n.signedOutPasswordChanged,
      SignOutReason.emailChanged => l10n.signedOutEmailChanged,
      SignOutReason.security => l10n.signedOutSecurity,
      SignOutReason.expired => l10n.signedOutExpired,
      SignOutReason.other => l10n.signedOutOther,
    };

/// The fingerprint of this phone as a way in: the account it signs in, a button
/// that asks for the fingerprint, and the way to the email and password form.
class _FingerprintCard extends StatelessWidget {
  const new({
    required this.account,
    required this.busy,
    required this.locked,
    required this.onSignIn,
    required this.onOtherAccount,
  });

  final FingerprintAccount account;
  final bool busy;
  final bool locked;
  final VoidCallback onSignIn;
  final VoidCallback onOtherAccount;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const IconCircle(
                  icon: LucideIcons.fingerprintPattern,
                  size: 56,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: MergeSemantics(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.signInAsName(name: account.name),
                          style: theme.textTheme.titleMedium,
                        ),
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(
                            account.maskedEmail,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: locked || busy ? null : onSignIn,
          icon: busy
              ? const ButtonSpinner()
              : const Icon(LucideIcons.fingerprintPattern),
          label: Text(l10n.signInWithFingerprintAction),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: busy ? null : onOtherAccount,
          child: Text(l10n.useAnotherAccountAction),
        ),
      ],
    );
  }
}
