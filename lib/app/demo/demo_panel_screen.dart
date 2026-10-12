import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';
import 'package:money_scribe/core/routing/app_routes.dart';
import 'package:money_scribe/features/auth/domain/auth_repository.dart';
import 'package:money_scribe/features/settings/bloc/language_bloc.dart';
import 'package:money_scribe/features/settings/domain/app_language.dart';

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
              const _Note(
                'Staging builds only. The server does not exist yet, so '
                'these switches decide what the fake data answers.',
              ),
              const _Heading('Language'),
              const _LanguagePicker(),
              const _Heading('Theme'),
              _ThemePicker(
                selected: settings.theme,
                onSelected: (value) =>
                    demo.update(demo.settings.copyWith(theme: value)),
              ),
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
              const _Heading('4-digit codes'),
              _Choice<DemoCode>(
                values: DemoCode.values,
                selected: settings.code,
                label: _codeLabel,
                onSelected: (value) =>
                    demo.update(demo.settings.copyWith(code: value)),
              ),
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

  static String _saveLabel(DemoSave value) => switch (value) {
    DemoSave.accepted => 'Works',
    DemoSave.fails => 'Fails (could not save)',
  };

  static String _signInLabel(DemoSignIn value) => switch (value) {
    DemoSignIn.accepted => 'Accepted (any email and password)',
    DemoSignIn.wrongPassword => 'Wrong password (locks after 5)',
    DemoSignIn.locked => 'Too many attempts (locked)',
  };

  static String _registrationLabel(DemoRegistration value) => switch (value) {
    DemoRegistration.accepted => 'Accepted (any data)',
    DemoRegistration.rejected => 'Rejected (field errors)',
  };

  static String _codeLabel(DemoCode value) => switch (value) {
    DemoCode.accepted => 'Accepted (any code)',
    DemoCode.wrong => 'Wrong (expires after 3 tries)',
    DemoCode.expired => 'Expired',
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
      child: SegmentedButton<AppLanguage>(
        showSelectedIcon: false,
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
  const new({required this.selected, required this.onSelected});

  final DemoTheme selected;
  final ValueChanged<DemoTheme> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SegmentedButton<DemoTheme>(
        showSelectedIcon: false,
        segments: const [
          ButtonSegment(value: DemoTheme.system, label: Text('System')),
          ButtonSegment(value: DemoTheme.light, label: Text('Light')),
          ButtonSegment(value: DemoTheme.dark, label: Text('Dark')),
        ],
        selected: {selected},
        onSelectionChanged: (selection) => onSelected(selection.first),
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
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap ?? () => context.push(path!),
    );
  }
}
