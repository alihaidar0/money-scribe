import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:money_scribe/core/formatting/bidi_isolate.dart';
import 'package:money_scribe/core/formatting/countdown_format.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/routing/app_routes.dart';
import 'package:money_scribe/core/time/ticker.dart';
import 'package:money_scribe/core/widgets/button_spinner.dart';
import 'package:money_scribe/core/widgets/code_boxes.dart';
import 'package:money_scribe/core/widgets/flow_page.dart';
import 'package:money_scribe/core/widgets/icon_circle.dart';
import 'package:money_scribe/core/widgets/linked_text.dart';
import 'package:money_scribe/core/widgets/message_banner.dart';
import 'package:money_scribe/core/widgets/state_view.dart';
import 'package:money_scribe/features/auth/bloc/code_verification_bloc.dart';
import 'package:money_scribe/features/auth/domain/auth_repository.dart';

/// The page where the 6-digit code sent by email is typed. It serves the
/// Verify your email screen (AUTH-4, 4b, 4c) and the Enter the code screen
/// (AUTH-8, 8b), which differ in their title, button and next step.
class CodeEntryPage extends StatelessWidget {
  const new({
    required this.purpose,
    required this.title,
    required this.actionLabel,
    required this.onVerified,
    this.codeWasSent = true,
    this.showAccountHint = false,
    super.key,
  });

  final CodePurpose purpose;
  final String title;

  /// The label of the button that checks the code.
  final String actionLabel;

  /// Whether a code is on its way. Off, the screen says the address is not
  /// verified yet and the person asks for a code.
  final bool codeWasSent;

  /// Shows the hint for someone who did not get a code because they already
  /// have an account.
  final bool showAccountHint;

  /// Opens the screen that follows a correct code.
  final void Function(BuildContext context) onVerified;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CodeVerificationBloc(
        purpose: purpose,
        repository: context.read<AuthRepository>(),
        ticker: context.read<Ticker>(),
      )..add(const CodeVerificationStarted()),
      child: _CodeEntryView(
        title: title,
        actionLabel: actionLabel,
        codeWasSent: codeWasSent,
        showAccountHint: showAccountHint,
        onVerified: onVerified,
      ),
    );
  }
}

class _CodeEntryView extends StatefulWidget {
  const new({
    required this.title,
    required this.actionLabel,
    required this.codeWasSent,
    required this.showAccountHint,
    required this.onVerified,
  });

  final String title;
  final String actionLabel;
  final bool codeWasSent;
  final bool showAccountHint;
  final void Function(BuildContext context) onVerified;

  @override
  State<_CodeEntryView> createState() => _CodeEntryViewState();
}

class _CodeEntryViewState extends State<_CodeEntryView> {
  final _code = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    // Open the keypad at once: the code is the only thing to do here.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _code.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit() {
    context.read<CodeVerificationBloc>().add(CodeSubmitted(_code.text));
  }

  void _onChanged(String code) {
    final bloc = context.read<CodeVerificationBloc>()..add(const CodeEdited());
    // The last digit checks the code without another press.
    if (code.length == CodeVerificationBloc.codeLength) {
      bloc.add(CodeSubmitted(code));
    }
  }

  void _resend() {
    _code.clear();
    context.read<CodeVerificationBloc>().add(const CodeResendRequested());
    _focus.requestFocus();
  }

  void _retry() {
    if (_code.text.length == CodeVerificationBloc.codeLength) {
      _submit();
    } else {
      context.read<CodeVerificationBloc>().add(const CodeEdited());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return BlocConsumer<CodeVerificationBloc, CodeVerificationState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == CodeVerificationStatus.verified) {
          widget.onVerified(context);
        } else if (state.status == CodeVerificationStatus.expired ||
            state.status == CodeVerificationStatus.attemptsExceeded) {
          _code.clear();
        }
      },
      builder: (context, state) {
        final isExpired = state.status == CodeVerificationStatus.expired;
        final isDead = state.status == CodeVerificationStatus.attemptsExceeded;
        final isWaiting = state.status == CodeVerificationStatus.rateLimited;
        final isWrong = state.status == CodeVerificationStatus.wrong;
        final isVerifying = state.status == CodeVerificationStatus.verifying;
        // The code cannot be typed while it is dead, old or the server says
        // to wait.
        final canType = !isExpired && !isDead && !isWaiting && !isVerifying;

        return FlowPage(
          failure: switch (state.status) {
            CodeVerificationStatus.noConnection => FailureKind.noConnection,
            CodeVerificationStatus.unavailable => FailureKind.unavailable,
            CodeVerificationStatus.failure => FailureKind.error,
            _ => null,
          },
          onRetry: _retry,
          content: [
            const Align(
              child: IconCircle(
                icon: Icons.mark_email_unread_outlined,
                size: 80,
              ),
            ),
            const SizedBox(height: 24),
            Semantics(
              header: true,
              child: Text(widget.title, style: theme.textTheme.headlineMedium),
            ),
            const SizedBox(height: 8),
            // The address keeps its left-to-right order inside Arabic text.
            Text(
              widget.codeWasSent
                  ? l10n.codeSentTo(email: isolateLeftToRight(state.email))
                  : l10n.emailNotVerifiedMessage(
                      email: isolateLeftToRight(state.email),
                    ),
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            if (isExpired) ...[
              MessageBanner(
                icon: Icons.schedule,
                text: l10n.codeExpired,
                tone: BannerTone.info,
              ),
              const SizedBox(height: 16),
            ],
            if (isDead) ...[
              MessageBanner(
                icon: Icons.lock_outline,
                text: l10n.codeAttemptsExceeded,
              ),
              const SizedBox(height: 16),
            ],
            if (isWaiting) ...[
              MessageBanner(
                icon: Icons.lock_outline,
                text: l10n.tooManyAttemptsTryAgain(
                  time: formatCountdown(state.waitSecondsLeft),
                ),
              ),
              const SizedBox(height: 16),
            ],
            CodeBoxes(
              length: CodeVerificationBloc.codeLength,
              controller: _code,
              focusNode: _focus,
              semanticLabel: l10n.codeFieldLabel,
              hasError: isWrong,
              enabled: canType,
              onChanged: _onChanged,
            ),
            if (isWrong) ...[
              const SizedBox(height: 12),
              _CodeError(text: _wrongCodeText(l10n, state.attemptsLeft)),
            ],
            const SizedBox(height: 16),
            _ResendRow(
              state: state,
              onResend: _resend,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ListenableBuilder(
              listenable: _code,
              builder: (context, _) {
                final complete =
                    _code.text.length == CodeVerificationBloc.codeLength;
                return FilledButton(
                  onPressed: complete && canType ? _submit : null,
                  child: isVerifying
                      ? const ButtonSpinner()
                      : Text(widget.actionLabel),
                );
              },
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: context.pop, child: Text(l10n.changeEmail)),
            if (widget.showAccountHint) ...[
              const SizedBox(height: 8),
              _AccountHint(style: theme.textTheme.bodyMedium),
            ],
          ],
        );
      },
    );
  }

  /// What a wrong code says. The server gives the tries left when it counts
  /// them; one or none left reads as the last try.
  String _wrongCodeText(AppLocalizations l10n, int? attemptsLeft) {
    if (attemptsLeft == null || attemptsLeft < 1) return l10n.codeIncorrect;
    return attemptsLeft > 1
        ? l10n.codeIncorrectAttemptsLeft(count: attemptsLeft)
        : l10n.codeIncorrectLastAttempt;
  }
}

/// "No code? You may already have an account": the answer to registering is
/// the same for an address that already has an account, so no code arrives.
/// The links lead to the two things that person wants.
class _AccountHint extends StatelessWidget {
  const new({required this.style});

  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return LinkedText(
      message: (links) =>
          l10n.verifyEmailHint(signIn: links[0], resetPassword: links[1]),
      links: [
        TextLink(
          l10n.verifyHintSignIn,
          onTap: () => context.go(AppRoutes.signIn),
        ),
        TextLink(
          l10n.verifyHintResetPassword,
          onTap: () => context.push(AppRoutes.forgotPassword),
        ),
      ],
      style: style,
      textAlign: TextAlign.center,
    );
  }
}

class _CodeError extends StatelessWidget {
  const new({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      liveRegion: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 18, color: colors.error),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: colors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResendRow extends StatelessWidget {
  const new({required this.state, required this.onResend, required this.style});

  final CodeVerificationState state;
  final VoidCallback onResend;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    // The server decides when a new code may be asked for: the button waits
    // for the countdown, in every state.
    if (state.resendSecondsLeft > 0) {
      return Text(
        l10n.resendCodeIn(time: formatCountdown(state.resendSecondsLeft)),
        style: style,
        textAlign: TextAlign.center,
      );
    }
    // A code that is old or dead needs a new one: make the button stand out.
    final needsNewCode =
        state.status == CodeVerificationStatus.expired ||
        state.status == CodeVerificationStatus.attemptsExceeded;
    if (needsNewCode) {
      return FilledButton.tonal(
        onPressed: onResend,
        child: Text(l10n.resendCode),
      );
    }
    return TextButton(onPressed: onResend, child: Text(l10n.resendCode));
  }
}
