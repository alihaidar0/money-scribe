import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';
import 'package:money_scribe/core/routing/app_routes.dart';
import 'package:money_scribe/core/widgets/pill_segmented_button.dart';
import 'package:money_scribe/features/auth/data/fake/fake_auth_repository.dart';
import 'package:money_scribe/features/auth/domain/auth_repository.dart';
import 'package:money_scribe/features/auth/domain/sign_out_reason.dart';
import 'package:money_scribe/features/settings/bloc/language_bloc.dart';
import 'package:money_scribe/features/settings/bloc/theme_bloc.dart';
import 'package:money_scribe/features/settings/domain/app_language.dart';
import 'package:money_scribe/features/settings/domain/theme_choice.dart';

/// The demo panel of staging builds: forces what the fake data does, so every
/// screen and state can be seen without a server, and jumps to the screens
/// that no button leads to. It is a tool for the people building the app, so
/// it is in English only, and it is deleted together with the fake data.
class DemoPanelScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final demo = context.read<DemoController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Demo panel')),
      body: StreamBuilder<DemoSettings>(
        initialData: demo.settings,
        stream: demo.changes,
        builder: (context, snapshot) {
          final settings = snapshot.requireData;

          return ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              _Note(
                demo.fakeAccount
                    ? 'Staging builds only. The server does not exist yet, so '
                          'these switches decide what the fake data answers.'
                    : 'Staging builds only. The account is on the real '
                          'server; these switches decide what the fake data '
                          'of the other screens answers.',
              ),
              const _Heading('Language'),
              const _LanguagePicker(),
              const _Heading('Theme'),
              const _ThemePicker(),
              const _Heading('Server'),
              _Choice<DemoScenario>(
                values: DemoScenario.values,
                selected: settings.scenario,
                label: _scenarioLabel,
                onSelected: (value) =>
                    demo.update(demo.settings.copyWith(scenario: value)),
              ),
              const _Heading('Payments per month'),
              _Choice<PaymentMode>(
                values: PaymentMode.values,
                selected: settings.paymentMode,
                label: _paymentModeLabel,
                onSelected: (value) =>
                    demo.update(demo.settings.copyWith(paymentMode: value)),
              ),
              if (demo.fakeAccount) ...[
                const _Heading('Sign in, next attempt'),
                _Choice<DemoSignIn>(
                  values: DemoSignIn.values,
                  selected: settings.signIn,
                  label: _signInLabel,
                  onSelected: (value) =>
                      demo.update(demo.settings.copyWith(signIn: value)),
                ),
                const _Heading('Create account, next attempt'),
                _Choice<DemoRegistration>(
                  values: DemoRegistration.values,
                  selected: settings.registration,
                  label: _registrationLabel,
                  onSelected: (value) =>
                      demo.update(demo.settings.copyWith(registration: value)),
                ),
                const _Heading('6-digit codes and new codes'),
                _Choice<DemoCode>(
                  values: DemoCode.values,
                  selected: settings.code,
                  label: _codeLabel,
                  onSelected: (value) =>
                      demo.update(demo.settings.copyWith(code: value)),
                ),
                const _Heading('New password after a reset, next attempt'),
                _Choice<DemoPasswordReset>(
                  values: DemoPasswordReset.values,
                  selected: settings.passwordReset,
                  label: _passwordResetLabel,
                  onSelected: (value) =>
                      demo.update(demo.settings.copyWith(passwordReset: value)),
                ),
                const _Heading(
                  'Change password and delete account, next attempt',
                ),
                _Choice<DemoPasswordChange>(
                  values: DemoPasswordChange.values,
                  selected: settings.passwordChange,
                  label: _passwordChangeLabel,
                  onSelected: (value) => demo.update(
                    demo.settings.copyWith(passwordChange: value),
                  ),
                ),
                const _Heading('Fingerprint sign-in, next attempt'),
                _Choice<DemoFingerprint>(
                  values: DemoFingerprint.values,
                  selected: settings.fingerprint,
                  label: _fingerprintLabel,
                  onSelected: (value) =>
                      demo.update(demo.settings.copyWith(fingerprint: value)),
                ),
                const _Heading('Server signs this device out (AUTH-2d)'),
                for (final reason in SignOutReason.values)
                  _GoTo(
                    label: _signOutLabel(reason),
                    onTap: () {
                      final auth = context.read<AuthRepository>();
                      if (auth is! FakeAuthRepository) return;
                      auth.endSession(reason);
                      context.go(AppRoutes.signIn);
                    },
                  ),
              ],
              const _Heading('Saving and deleting, next attempt'),
              _Choice<DemoSave>(
                values: DemoSave.values,
                selected: settings.save,
                label: _saveLabel,
                onSelected: (value) =>
                    demo.update(demo.settings.copyWith(save: value)),
              ),
              const _Heading('Go to'),
              _GoTo(
                label: 'Sign out and show Welcome',
                onTap: () async {
                  await context.read<AuthRepository>().signOut();
                  if (context.mounted) context.go(AppRoutes.welcome);
                },
              ),
              const _GoTo(
                label: 'How are you paid? (AUTH-6)',
                path: AppRoutes.paySetup,
              ),
              const _GoTo(
                label: 'Email verified (AUTH-5)',
                path: AppRoutes.emailVerified,
              ),
              const _GoTo(
                label: 'Password changed (AUTH-10)',
                path: AppRoutes.passwordChanged,
              ),
              const _GoTo(label: 'App lock (AUTH-11)', path: AppRoutes.appLock),
              const _GoTo(
                label: 'PIN entry (AUTH-12)',
                path: AppRoutes.pinEntry,
              ),
              const _GoTo(
                label: 'Create a PIN (AUTH-13)',
                path: AppRoutes.createPin,
              ),
            ],
          );
        },
      ),
    );
  }

  static String _scenarioLabel(DemoScenario value) => switch (value) {
    DemoScenario.normal => 'Normal',
    DemoScenario.loading => 'Loading (slow answers)',
    DemoScenario.empty => 'Empty (no data)',
    DemoScenario.error => 'Error (server fails)',
    DemoScenario.noConnection => 'No connection',
  };

  static String _paymentModeLabel(PaymentMode value) => switch (value) {
    PaymentMode.onePayment => 'One payment',
    PaymentMode.twoPayments => 'Two payments (parts)',
  };

  static String _signOutLabel(SignOutReason value) => switch (value) {
    SignOutReason.tooManyDevices => 'Too many devices',
    SignOutReason.endedElsewhere => 'Ended from another device',
    SignOutReason.passwordChanged => 'Password changed',
    SignOutReason.emailChanged => 'Email changed',
    SignOutReason.security => 'To protect the account (token reuse)',
    SignOutReason.expired => 'Session expired',
    SignOutReason.other => 'Another reason',
  };

  static String _saveLabel(DemoSave value) => switch (value) {
    DemoSave.accepted => 'Works',
    DemoSave.fails => 'Fails (could not save)',
  };

  static String _signInLabel(DemoSignIn value) => switch (value) {
    DemoSignIn.accepted => 'Accepted (any email and password)',
    DemoSignIn.emailNotRegistered => 'Email not registered',
    DemoSignIn.wrongPassword => 'Wrong password (locks after 5)',
    DemoSignIn.challengeRequired => 'Bot check (any solution signs in)',
    DemoSignIn.challengeRejected => 'Bot check (every solution refused)',
    DemoSignIn.locked => 'Too many attempts (locked)',
    DemoSignIn.emailNotVerified => 'Email not verified',
    DemoSignIn.unavailable => 'Server busy (try again shortly)',
  };

  static String _registrationLabel(DemoRegistration value) => switch (value) {
    DemoRegistration.accepted => 'Accepted (any data)',
    DemoRegistration.rejected => 'Rejected (field errors)',
    DemoRegistration.tooSoon => 'Too soon (wait, then send again)',
    DemoRegistration.unavailable => 'Server busy (try again shortly)',
  };

  static String _passwordResetLabel(DemoPasswordReset value) => switch (value) {
    DemoPasswordReset.accepted => 'Accepted (any password)',
    DemoPasswordReset.passwordRefused => 'Password refused (too short)',
    DemoPasswordReset.tokenInvalid => 'Reset ran out (start again)',
    DemoPasswordReset.tooSoon => 'Too many requests (wait)',
    DemoPasswordReset.unavailable => 'Server busy (try again shortly)',
  };

  static String _passwordChangeLabel(DemoPasswordChange value) =>
      switch (value) {
        DemoPasswordChange.accepted => 'Accepted (wrong current: see Sign in)',
        DemoPasswordChange.passwordRefused =>
          'New password refused (too short)',
        DemoPasswordChange.locked => 'Locked after wrong passwords (wait)',
        DemoPasswordChange.unavailable => 'Server busy (try again shortly)',
      };

  static String _fingerprintLabel(DemoFingerprint value) => switch (value) {
    DemoFingerprint.accepted => 'Accepted (wrong password: see Sign in)',
    DemoFingerprint.notEnrolled => 'Phone has no fingerprint enrolled',
    DemoFingerprint.unsupported => 'Phone cannot hold the key',
    DemoFingerprint.notMatched => 'Fingerprint did not match',
    DemoFingerprint.attestationRefused => 'Server refuses the key',
    DemoFingerprint.limitReached => 'Five phones already (limit)',
    DemoFingerprint.signInRefused => 'Sign-in refused (use the password)',
    DemoFingerprint.locked => 'Locked after failures (wait)',
    DemoFingerprint.unavailable => 'Server busy (try again shortly)',
  };

  static String _codeLabel(DemoCode value) => switch (value) {
    DemoCode.accepted => 'Accepted (any code)',
    DemoCode.wrong => 'Wrong (dead after 5 tries)',
    DemoCode.expired => 'Expired',
    DemoCode.attemptsExceeded => 'Too many tries (dead, wait for a new one)',
    DemoCode.unavailable => 'Server busy (try again shortly)',
  };
}

class _Heading extends StatelessWidget {
  const new(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 24, 16, 4),
      child: Text(text, style: Theme.of(context).textTheme.labelLarge),
    );
  }
}

class _Note extends StatelessWidget {
  const new(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

class _Choice<T> extends StatelessWidget {
  const new({
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelected,
  });

  final List<T> values;
  final T selected;
  final String Function(T value) label;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return RadioGroup<T>(
      groupValue: selected,
      onChanged: (value) {
        if (value != null) onSelected(value);
      },
      child: Column(
        children: [
          for (final value in values)
            RadioListTile<T>(
              dense: true,
              value: value,
              title: Text(label(value)),
            ),
        ],
      ),
    );
  }
}

class _LanguagePicker extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final language = context.select<LanguageBloc, AppLanguage>(
      (bloc) => bloc.state.language,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: PillSegmentedButton<AppLanguage>(
        segments: const [
          ButtonSegment(value: AppLanguage.system, label: Text('System')),
          ButtonSegment(value: AppLanguage.english, label: Text('English')),
          ButtonSegment(value: AppLanguage.arabic, label: Text('العربية')),
        ],
        selected: {language},
        onSelectionChanged: (selection) =>
            context.read<LanguageBloc>().add(LanguageSelected(selection.first)),
      ),
    );
  }
}

class _ThemePicker extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final choice = context.select<ThemeBloc, ThemeChoice>(
      (bloc) => bloc.state.choice,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: PillSegmentedButton<ThemeChoice>(
        segments: const [
          ButtonSegment(value: ThemeChoice.system, label: Text('System')),
          ButtonSegment(value: ThemeChoice.light, label: Text('Light')),
          ButtonSegment(value: ThemeChoice.dark, label: Text('Dark')),
        ],
        selected: {choice},
        onSelectionChanged: (selection) =>
            context.read<ThemeBloc>().add(ThemeSelected(selection.first)),
      ),
    );
  }
}

class _GoTo extends StatelessWidget {
  const new({required this.label, this.path, this.onTap});

  final String label;
  final String? path;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      title: Text(label),
      trailing: const Icon(LucideIcons.chevronRightDir),
      onTap: onTap ?? () => context.push(path!),
    );
  }
}
