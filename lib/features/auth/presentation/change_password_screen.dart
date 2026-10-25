import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:money_scribe/core/formatting/countdown_format.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/routing/app_routes.dart';
import 'package:money_scribe/core/routing/navigation_extensions.dart';
import 'package:money_scribe/core/time/ticker.dart';
import 'package:money_scribe/core/widgets/password_field.dart';
import 'package:money_scribe/core/widgets/pinned_button_bar.dart';
import 'package:money_scribe/core/widgets/state_view.dart';
import 'package:money_scribe/core/widgets/success_snack_bar.dart';
import 'package:money_scribe/features/auth/bloc/change_password_bloc.dart';
import 'package:money_scribe/features/auth/bloc/device_key_setting_bloc.dart';
import 'package:money_scribe/features/auth/domain/auth_repository.dart';
import 'package:money_scribe/features/auth/domain/device_key_repository.dart';
import 'package:money_scribe/features/auth/presentation/password_problem_text.dart';
import 'package:money_scribe/features/auth/presentation/widgets/fingerprint_sign_in_tile.dart';
import 'package:money_scribe/features/auth/presentation/widgets/turn_fingerprint_back_on_dialog.dart';

/// ST-6: change the password: the current one, and a new one typed twice.
/// Saving goes back to the Account screen with a message. When the fingerprint
/// sign-in was on, the server removed its key with the old password, so the
/// person is first offered to turn it on again, with the password just typed.
class ChangePasswordScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => ChangePasswordBloc(
            repository: context.read<AuthRepository>(),
            deviceKeys: context.read<DeviceKeyRepository>(),
            ticker: context.read<Ticker>(),
          ),
        ),
        BlocProvider(
          create: (context) => DeviceKeySettingBloc(
            repository: context.read<DeviceKeyRepository>(),
          ),
        ),
      ],
      child: const _ChangePasswordView(),
    );
  }
}

class _ChangePasswordView extends StatefulWidget {
  const new();

  @override
  State<_ChangePasswordView> createState() => _ChangePasswordViewState();
}

class _ChangePasswordViewState extends State<_ChangePasswordView> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirmation = TextEditingController();

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  void _edited(String _) {
    context.read<ChangePasswordBloc>().add(
      ChangePasswordEdited(
        current: _current.text,
        next: _next.text,
        confirmation: _confirmation.text,
      ),
    );
  }

  void _submit() {
    context.read<ChangePasswordBloc>().add(const ChangePasswordSubmitted());
  }

  /// The password was saved: say so, offer the fingerprint again when its key
  /// was removed, and leave. Turning it on leaves when it has ended.
  Future<void> _saved(ChangePasswordState state) async {
    final l10n = context.l10n;
    final deviceKeys = context.read<DeviceKeySettingBloc>();
    showSuccessSnackBar(context, l10n.passwordChangedTitle);
    if (state.offerFingerprint) {
      final accepted = await confirmTurnFingerprintBackOn(context);
      if (!mounted) return;
      if (accepted) {
        deviceKeys.add(
          FingerprintSignInTurnedOn(
            password: state.next,
            prompt: l10n.fingerprintSignInReason,
          ),
        );
        return;
      }
    }
    context.popOrGo(AppRoutes.account);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DeviceKeySettingBloc, DeviceKeySettingState>(
      listenWhen: (previous, current) =>
          previous.outcome != current.outcome && current.outcome != null,
      listener: (context, state) {
        // Turning the fingerprint back on has ended, well or not: say how, and
        // leave. The password is saved either way.
        tellDeviceKeyOutcome(context, state);
        context.popOrGo(AppRoutes.account);
      },
      child: _form(context),
    );
  }

  Widget _form(BuildContext context) {
    final l10n = context.l10n;
    // The password is saved; the fingerprint is being turned on again.
    final turningOnFingerprint = context.select<DeviceKeySettingBloc, bool>(
      (bloc) => bloc.state.isBusy,
    );

    return BlocConsumer<ChangePasswordBloc, ChangePasswordState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == ChangePasswordStatus.saved,
      listener: (context, state) => unawaited(_saved(state)),
      builder: (context, state) {
        final failure = switch (state.status) {
          ChangePasswordStatus.unavailable => FailureKind.unavailable,
          ChangePasswordStatus.noConnection => FailureKind.noConnection,
          ChangePasswordStatus.failure => FailureKind.error,
          _ => null,
        };
        final isBusy = state.status == ChangePasswordStatus.saving;
        final isWaiting = state.status == ChangePasswordStatus.waiting;
        final problem = state.passwordProblem;

        return Scaffold(
          appBar: AppBar(title: Text(l10n.changePasswordTitle)),
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
                      PasswordField(
                        controller: _current,
                        label: l10n.currentPasswordLabel,
                        enabled: !isBusy,
                        textInputAction: TextInputAction.next,
                        errorText:
                            state.status == ChangePasswordStatus.wrongCurrent
                            ? l10n.changePasswordWrongCurrent
                            : null,
                        onChanged: _edited,
                      ),
                      const SizedBox(height: 16),
                      PasswordField(
                        controller: _next,
                        label: l10n.newPasswordLabel,
                        enabled: !isBusy,
                        textInputAction: TextInputAction.next,
                        errorText: problem == null
                            ? null
                            : passwordProblemText(l10n, problem),
                        autofillHints: const [AutofillHints.newPassword],
                        onChanged: _edited,
                      ),
                      const SizedBox(height: 16),
                      PasswordField(
                        controller: _confirmation,
                        label: l10n.confirmNewPasswordLabel,
                        enabled: !isBusy,
                        errorText: state.mismatch
                            ? l10n.registerPasswordsMismatch
                            : null,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.newPassword],
                        onChanged: _edited,
                        onSubmitted: (_) {
                          if (state.isValid && !isBusy && !isWaiting) _submit();
                        },
                      ),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: TextButton(
                          onPressed: isBusy
                              ? null
                              : () => context.push(AppRoutes.forgotPassword),
                          child: Text(l10n.forgotYourPasswordLink),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (failure != null)
                Positioned.fill(
                  child: FailureView(kind: failure, onRetry: _submit),
                ),
              if (turningOnFingerprint)
                Positioned.fill(
                  child: ColoredBox(
                    color: Theme.of(context).colorScheme.scrim
                        .withValues(alpha: 0.3),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
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
                      : l10n.savePassword,
                  isBusy: isBusy,
                  onPressed: state.isValid && !isBusy && !isWaiting
                      ? _submit
                      : null,
                )
              : null,
        );
      },
    );
  }
}
