import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/routing/app_routes.dart';
import 'package:money_scribe/core/routing/navigation_extensions.dart';
import 'package:money_scribe/core/widgets/password_field.dart';
import 'package:money_scribe/core/widgets/pinned_button_bar.dart';
import 'package:money_scribe/core/widgets/state_view.dart';
import 'package:money_scribe/core/widgets/success_snack_bar.dart';
import 'package:money_scribe/features/auth/bloc/change_password_bloc.dart';
import 'package:money_scribe/features/auth/domain/auth_repository.dart';

/// ST-6: change the password: the current one, and a new one typed twice.
/// Saving goes back to the Account screen with a message.
class ChangePasswordScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          ChangePasswordBloc(repository: context.read<AuthRepository>()),
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocConsumer<ChangePasswordBloc, ChangePasswordState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == ChangePasswordStatus.saved,
      listener: (context, state) {
        showSuccessSnackBar(context, l10n.passwordChangedTitle);
        context.popOrGo(AppRoutes.account);
      },
      builder: (context, state) {
        final failure = switch (state.status) {
          ChangePasswordStatus.notAvailable => FailureKind.notAvailable,
          ChangePasswordStatus.noConnection => FailureKind.noConnection,
          ChangePasswordStatus.failure => FailureKind.error,
          _ => null,
        };
        final isBusy = state.status == ChangePasswordStatus.saving;

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
                          if (state.isValid && !isBusy) _submit();
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
            ],
          ),
          bottomNavigationBar: failure == null
              ? PinnedButtonBar(
                  label: l10n.savePassword,
                  isBusy: isBusy,
                  onPressed: state.isValid && !isBusy ? _submit : null,
                )
              : null,
        );
      },
    );
  }
}
