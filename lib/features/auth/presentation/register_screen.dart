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
import 'package:money_scribe/core/widgets/linked_text.dart';
import 'package:money_scribe/core/widgets/password_field.dart';
import 'package:money_scribe/core/widgets/state_view.dart';
import 'package:money_scribe/features/auth/bloc/register_bloc.dart';
import 'package:money_scribe/features/auth/domain/auth_repository.dart';
import 'package:money_scribe/features/auth/presentation/password_problem_text.dart';
import 'package:money_scribe/features/auth/presentation/verify_email_screen.dart';

/// AUTH-3 and AUTH-3b: create an account.
class RegisterScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RegisterBloc(
        repository: context.read<AuthRepository>(),
        ticker: context.read<Ticker>(),
      ),
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
        // The password is sent as typed: spaces are part of it.
        password: _password.text,
        confirmation: _confirmation.text,
      ),
    );
  }

  bool _canSubmit({required bool isBusy, required bool isWaiting}) {
    return _agreed && !isBusy && !isWaiting && _password.text.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return BlocConsumer<RegisterBloc, RegisterState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == RegisterStatus.success,
      // A code is on its way (or the address already has an account): either
      // way the next step is the same screen.
      listener: (context, state) => context.push(
        AppRoutes.verifyEmail,
        extra: VerifyEmailOrigin.registration,
      ),
      builder: (context, state) {
        final isBusy = state.status == RegisterStatus.submitting;
        final isWaiting = state.status == RegisterStatus.waiting;
        final problem = state.passwordProblem;

        return FlowPage(
          failure: switch (state.status) {
            RegisterStatus.noConnection => FailureKind.noConnection,
            RegisterStatus.unavailable => FailureKind.unavailable,
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
              errorText: state.nameInvalid ? l10n.registerNameInvalid : null,
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
              errorText: state.emailInvalid ? l10n.registerEmailInvalid : null,
            ),
            const SizedBox(height: 16),
            // No hint about length or content: the server owns the password
            // policy and says what is wrong after the account is sent.
            PasswordField(
              controller: _password,
              label: l10n.passwordLabel,
              enabled: !isBusy,
              errorText: problem == null
                  ? null
                  : passwordProblemText(l10n, problem),
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
            ),
            const SizedBox(height: 16),
            PasswordField(
              controller: _confirmation,
              label: l10n.confirmPasswordLabel,
              enabled: !isBusy,
              errorText: state.passwordsDoNotMatch
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
            // A password has to be typed; nothing else is asked of it here.
            ListenableBuilder(
              listenable: _password,
              builder: (context, _) => FilledButton(
                onPressed: _canSubmit(isBusy: isBusy, isWaiting: isWaiting)
                    ? _submit
                    : null,
                child: switch (state.status) {
                  RegisterStatus.submitting => const ButtonSpinner(),
                  // The server asked to wait: the button counts down.
                  RegisterStatus.waiting => Text(
                    l10n.tryAgainIn(
                      time: formatCountdown(state.waitSecondsLeft),
                    ),
                  ),
                  _ => Text(l10n.createAccount),
                },
              ),
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
