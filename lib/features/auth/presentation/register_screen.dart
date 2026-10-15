import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/routing/app_routes.dart';
import 'package:money_scribe/core/widgets/app_text_field.dart';
import 'package:money_scribe/core/widgets/button_spinner.dart';
import 'package:money_scribe/core/widgets/flow_page.dart';
import 'package:money_scribe/core/widgets/linked_text.dart';
import 'package:money_scribe/core/widgets/password_field.dart';
import 'package:money_scribe/core/widgets/state_view.dart';
import 'package:money_scribe/features/auth/bloc/register_bloc.dart';
import 'package:money_scribe/features/auth/domain/auth_exception.dart';
import 'package:money_scribe/features/auth/domain/auth_repository.dart';

/// AUTH-3 and AUTH-3b: create an account.
class RegisterScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          RegisterBloc(repository: context.read<AuthRepository>()),
      child: const _RegisterView(),
    );
  }
}

class _RegisterView extends StatefulWidget {
  const new();

  @override
  State<_RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<_RegisterView> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _agreed = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  void _submit() {
    context.read<RegisterBloc>().add(
      RegisterSubmitted(
        name: _name.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return BlocConsumer<RegisterBloc, RegisterState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == RegisterStatus.success,
      listener: (context, state) => context.push(AppRoutes.verifyEmail),
      builder: (context, state) {
        final isBusy = state.status == RegisterStatus.submitting;
        final problems = state.problems;

        return FlowPage(
          failure: switch (state.status) {
            RegisterStatus.noConnection => FailureKind.noConnection,
            RegisterStatus.failure => FailureKind.error,
            _ => null,
          },
          onRetry: _submit,
          content: [
            Semantics(
              header: true,
              child: Text(
                l10n.createAccount,
                style: theme.textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: 8),
            Text(l10n.registerSentence, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 24),
            AppTextField(
              controller: _name,
              label: l10n.nameLabel,
              enabled: !isBusy,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _email,
              label: l10n.emailLabel,
              enabled: !isBusy,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              textDirection: TextDirection.ltr,
              error: problems.contains(RegistrationProblem.emailTaken)
                  ? LinkedText(
                      message: (links) =>
                          l10n.registerEmailTaken(signIn: links[0]),
                      links: [
                        TextLink(
                          l10n.signIn,
                          onTap: () =>
                              context.pushReplacement(AppRoutes.signIn),
                        ),
                      ],
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            PasswordField(
              controller: _password,
              label: l10n.passwordLabel,
              enabled: !isBusy,
              helperText: l10n.passwordRuleLength,
              errorText: problems.contains(RegistrationProblem.passwordTooShort)
                  ? l10n.registerPasswordTooShort
                  : null,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
            ),
            const SizedBox(height: 16),
            PasswordField(
              controller: _confirmation,
              label: l10n.confirmPasswordLabel,
              enabled: !isBusy,
              errorText:
                  problems.contains(RegistrationProblem.passwordsDoNotMatch)
                  ? l10n.registerPasswordsMismatch
                  : null,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _agreed,
              onChanged: isBusy
                  ? null
                  : (value) => setState(() => _agreed = value ?? false),
              // The Terms and the Privacy Policy are not written yet, so
              // their links do nothing for now.
              title: LinkedText(
                message: (links) =>
                    l10n.registerAgreement(terms: links[0], privacy: links[1]),
                links: [
                  TextLink(l10n.termsName),
                  TextLink(l10n.privacyPolicyName),
                ],
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _agreed && !isBusy ? _submit : null,
              child: isBusy ? const ButtonSpinner() : Text(l10n.createAccount),
            ),
          ],
          bottomChildren: [
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  l10n.alreadyHaveAccount,
                  style: theme.textTheme.bodyMedium,
                ),
                TextButton(
                  onPressed: () => context.pushReplacement(AppRoutes.signIn),
                  child: Text(l10n.signIn),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
