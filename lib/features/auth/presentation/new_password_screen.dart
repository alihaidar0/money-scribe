import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/routing/app_routes.dart';
import 'package:money_scribe/core/widgets/button_spinner.dart';
import 'package:money_scribe/core/widgets/flow_page.dart';
import 'package:money_scribe/core/widgets/password_field.dart';
import 'package:money_scribe/core/widgets/state_view.dart';
import 'package:money_scribe/features/auth/bloc/new_password_bloc.dart';
import 'package:money_scribe/features/auth/domain/auth_repository.dart';

/// AUTH-9: choose a new password, typed twice. The app checks only that the
/// two fields are the same: the server owns every other password rule.
class NewPasswordScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          NewPasswordBloc(repository: context.read<AuthRepository>()),
      child: const _NewPasswordView(),
    );
  }
}

class _NewPasswordView extends StatefulWidget {
  const new();

  @override
  State<_NewPasswordView> createState() => _NewPasswordViewState();
}

class _NewPasswordViewState extends State<_NewPasswordView> {
  final _password = TextEditingController();
  final _confirmation = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  void _changed(String _) {
    context.read<NewPasswordBloc>().add(
      NewPasswordChanged(
        password: _password.text,
        confirmation: _confirmation.text,
      ),
    );
  }

  void _submit() {
    context.read<NewPasswordBloc>().add(NewPasswordSubmitted(_password.text));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return BlocConsumer<NewPasswordBloc, NewPasswordState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == NewPasswordStatus.saved,
      listener: (context, state) => context.go(AppRoutes.passwordChanged),
      builder: (context, state) {
        final isBusy = state.status == NewPasswordStatus.saving;

        return FlowPage(
          failure: switch (state.status) {
            NewPasswordStatus.notAvailable => FailureKind.notAvailable,
            NewPasswordStatus.noConnection => FailureKind.noConnection,
            NewPasswordStatus.failure => FailureKind.error,
            _ => null,
          },
          onRetry: _submit,
          content: [
            Semantics(
              header: true,
              child: Text(
                l10n.newPasswordTitle,
                style: theme.textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: 24),
            PasswordField(
              controller: _password,
              label: l10n.newPasswordLabel,
              enabled: !isBusy,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              onChanged: _changed,
            ),
            const SizedBox(height: 16),
            PasswordField(
              controller: _confirmation,
              label: l10n.confirmPasswordLabel,
              enabled: !isBusy,
              errorText: state.mismatch ? l10n.registerPasswordsMismatch : null,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              onChanged: _changed,
              onSubmitted: (_) {
                if (state.isValid && !isBusy) _submit();
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: state.isValid && !isBusy ? _submit : null,
              child: isBusy ? const ButtonSpinner() : Text(l10n.savePassword),
            ),
          ],
        );
      },
    );
  }
}
