import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:money_scribe/core/formatting/bidi_isolate.dart';
import 'package:money_scribe/core/formatting/countdown_format.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/time/ticker.dart';
import 'package:money_scribe/core/widgets/button_spinner.dart';
import 'package:money_scribe/core/widgets/code_boxes.dart';
import 'package:money_scribe/core/widgets/flow_page.dart';
import 'package:money_scribe/core/widgets/icon_circle.dart';
import 'package:money_scribe/core/widgets/message_banner.dart';
import 'package:money_scribe/core/widgets/state_view.dart';
import 'package:money_scribe/features/auth/bloc/code_verification_bloc.dart';
import 'package:money_scribe/features/auth/domain/auth_repository.dart';

/// The page where the 4-digit code sent by email is typed. It serves the
/// Verify your email screen (AUTH-4, 4b, 4c) and the Enter the code screen
/// (AUTH-8, 8b), which differ in their title, button and next step.
class CodeEntryPage extends StatelessWidget {
  const new({
    required this.purpose,
    required this.title,
    required this.actionLabel,
    required this.onVerified,
    super.key,
  });

  final CodePurpose purpose;
  final String title;

  /// The label of the button that checks the code.
  final String actionLabel;

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
        onVerified: onVerified,
      ),
    );
  }
}

class _CodeEntryView extends StatefulWidget {
  const new({
    required this.title,
    required this.actionLabel,
    required this.onVerified,
  });

  final String title;
  final String actionLabel;
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
        } else if (state.status == CodeVerificationStatus.expired) {
          _code.clear();
        }
      },
      builder: (context, state) {
        final isExpired = state.status == CodeVerificationStatus.expired;
        final isWrong = state.status == CodeVerificationStatus.wrong;
        final isVerifying = state.status == CodeVerificationStatus.verifying;

        return FlowPage(
          failure: switch (state.status) {
            CodeVerificationStatus.noConnection => FailureKind.noConnection,
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
              l10n.codeSentTo(email: isolateLeftToRight(state.email)),
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
            CodeBoxes(
              controller: _code,
              focusNode: _focus,
              semanticLabel: l10n.codeFieldLabel,
              hasError: isWrong,
              enabled: !isExpired && !isVerifying,
              onChanged: _onChanged,
            ),
            if (isWrong) ...[
              const SizedBox(height: 12),
              _CodeError(
                text: state.attemptsLeft > 1
                    ? l10n.codeIncorrectAttemptsLeft(count: state.attemptsLeft)
                    : l10n.codeIncorrectLastAttempt,
              ),
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
                  onPressed: complete && !isExpired && !isVerifying
                      ? _submit
                      : null,
                  child: isVerifying
                      ? const ButtonSpinner()
                      : Text(widget.actionLabel),
                );
              },
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: context.pop, child: Text(l10n.changeEmail)),
          ],
        );
      },
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

    if (state.status == CodeVerificationStatus.expired) {
      return FilledButton.tonal(
        onPressed: onResend,
        child: Text(l10n.resendCode),
      );
    }
    if (state.resendSecondsLeft > 0) {
      return Text(
        l10n.resendCodeIn(time: formatCountdown(state.resendSecondsLeft)),
        style: style,
        textAlign: TextAlign.center,
      );
    }
    return TextButton(onPressed: onResend, child: Text(l10n.resendCode));
  }
}
