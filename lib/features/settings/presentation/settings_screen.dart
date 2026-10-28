import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:money_scribe/core/environment/app_version.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';
import 'package:money_scribe/core/routing/app_routes.dart';
import 'package:money_scribe/core/widgets/failure_snack_bar.dart';
import 'package:money_scribe/core/widgets/message_banner.dart';
import 'package:money_scribe/core/widgets/pill_segmented_button.dart';
import 'package:money_scribe/core/widgets/success_snack_bar.dart';
import 'package:money_scribe/core/widgets/wide_frame.dart';
import 'package:money_scribe/features/auth/presentation/widgets/account_settings_tile.dart';
import 'package:money_scribe/features/auth/presentation/widgets/app_lock_settings_tile.dart';
import 'package:money_scribe/features/auth/presentation/widgets/fingerprint_sign_in_tile.dart';
import 'package:money_scribe/features/notifications/presentation/notifications_settings_section.dart';
import 'package:money_scribe/features/settings/bloc/language_bloc.dart';
import 'package:money_scribe/features/settings/bloc/settings_bloc.dart';
import 'package:money_scribe/features/settings/bloc/theme_bloc.dart';
import 'package:money_scribe/features/settings/domain/app_language.dart';
import 'package:money_scribe/features/settings/domain/default_currency_repository.dart';
import 'package:money_scribe/features/settings/domain/pay_schedule_repository.dart';
import 'package:money_scribe/features/settings/domain/theme_choice.dart';
import 'package:money_scribe/features/settings/presentation/widgets/csv_export_password_dialog.dart';
import 'package:money_scribe/features/settings/presentation/widgets/csv_export_sheet.dart';
import 'package:money_scribe/features/settings/presentation/widgets/currency_names.dart';
import 'package:money_scribe/features/settings/presentation/widgets/currency_sheet.dart';

/// ST-1: the Settings: the account, how the salary is paid, the currency, the
/// theme and the language, the notifications, the data (categories, accounts,
/// CSV) and the app lock. Each row that needs more opens its own screen. On a
/// wide window the sections are a list on one side and the chosen section is
/// on the other.
class SettingsScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SettingsBloc(
        paySchedule: context.read<PayScheduleRepository>(),
        currency: context.read<DefaultCurrencyRepository>(),
      )..add(const SettingsStarted()),
      child: const _SettingsView(),
    );
  }
}

/// The window width from which the sections are listed beside the chosen
/// one (the expanded window size class).
const _sectionsPaneFrom = 840.0;

/// The width of the list of sections on a wide window.
const _sectionListWidth = 280.0;

/// The widest the rows of a section grow on a wide window.
const _sectionWidth = 640.0;

class _SettingsView extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocListener<SettingsBloc, SettingsState>(
      listenWhen: (previous, current) =>
          previous.failedAction != current.failedAction &&
          current.failedAction != null,
      listener: (context, state) {
        final action = state.failedAction;
        if (action == null) return;
        showFailureSnackBar(
          context,
          l10n.couldNotSave,
          onRetry: () => context.read<SettingsBloc>().add(action),
        );
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.settingsTitle)),
        body: LayoutBuilder(
          builder: (context, constraints) =>
              constraints.maxWidth >= _sectionsPaneFrom
              ? const _SectionsPane()
              : const _SectionsList(),
        ),
      ),
    );
  }
}

/// The sections of the Settings, to name their headings.
enum _Section {
  account(LucideIcons.user),
  payments(LucideIcons.calendarSync),
  preferences(LucideIcons.slidersHorizontal),
  data(LucideIcons.folderOpen),
  security(LucideIcons.lock);

  new(this.icon);

  final IconData icon;

  /// The rows of the section.
  List<Widget> get rows => switch (this) {
    _Section.account => const [AccountSettingsTile()],
    _Section.payments => const [_PayScheduleRow()],
    _Section.preferences => const [
      _CurrencyRow(),
      _ThemeRow(),
      _LanguageRow(),
      _Notifications(),
    ],
    _Section.data => const [_DataRows()],
    _Section.security => const [
      AppLockSettingsTile(),
      FingerprintSignInTile(),
      _SecurityRows(),
    ],
  };

  String title(AppLocalizations l10n) => switch (this) {
    _Section.account => l10n.accountTitle,
    _Section.payments => l10n.settingsPaymentsSection,
    _Section.preferences => l10n.settingsPreferencesSection,
    _Section.data => l10n.settingsDataSection,
    _Section.security => l10n.settingsSecuritySection,
  };
}

/// Every section one under the other, as on a phone.
class _SectionsList extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: FrameWidth.narrow.value),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            const _LoadFailedBanner(),
            for (final section in _Section.values) ...[
              _Heading(section),
              ...section.rows,
            ],
            const _Version(),
          ],
        ),
      ),
    );
  }
}

/// A wide window: the list of sections, and the rows of the chosen one.
class _SectionsPane extends StatefulWidget {
  const new();

  @override
  State<_SectionsPane> createState() => _SectionsPaneState();
}

class _SectionsPaneState extends State<_SectionsPane> {
  _Section _selected = _Section.account;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Row(
      children: [
        SizedBox(
          width: _sectionListWidth,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    for (final section in _Section.values)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: ListTile(
                          selected: section == _selected,
                          selectedTileColor:
                              theme.colorScheme.secondaryContainer,
                          selectedColor: theme.colorScheme.onSecondaryContainer,
                          shape: const StadiumBorder(),
                          leading: Icon(section.icon),
                          title: Text(section.title(l10n)),
                          onTap: () => setState(() => _selected = section),
                        ),
                      ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: _Version(),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _sectionWidth),
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: [
                  const _LoadFailedBanner(),
                  Semantics(
                    header: true,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Text(
                        _selected.title(l10n),
                        style: theme.textTheme.headlineSmall,
                      ),
                    ),
                  ),
                  ..._selected.rows,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Heading extends StatelessWidget {
  const new(this.section);

  final _Section section;

  @override
  Widget build(BuildContext context) {
    final title = section.title(context.l10n);

    return Semantics(
      header: true,
      child: ListTile(
        title: Text(title, style: Theme.of(context).textTheme.labelLarge),
      ),
    );
  }
}

/// A chevron that points to the end of the line: it mirrors in Arabic.
class _Chevron extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return Icon(
      Directionality.of(context) == TextDirection.rtl
          ? LucideIcons.chevronLeft
          : LucideIcons.chevronRight,
    );
  }
}

/// Tells that the pay schedule and the currency could not be loaded, with a
/// way to try again.
class _LoadFailedBanner extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final failed = context.select<SettingsBloc, bool>(
      (bloc) =>
          bloc.state.status == SettingsStatus.noConnection ||
          bloc.state.status == SettingsStatus.failure,
    );
    if (!failed) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MessageBanner(
            icon: LucideIcons.circleAlert,
            text: l10n.settingsLoadFailed,
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: () =>
                  context.read<SettingsBloc>().add(const SettingsRetried()),
              child: Text(l10n.tryAgain),
            ),
          ),
        ],
      ),
    );
  }
}

class _PayScheduleRow extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<SettingsBloc>().state;
    final loaded = state.status == SettingsStatus.ready;

    return ListTile(
      leading: const Icon(LucideIcons.calendarSync),
      title: Text(l10n.payScheduleTitle),
      subtitle: Text(
        !loaded
            ? '—'
            : switch (state.schedule.mode) {
                PaymentMode.onePayment => l10n.payScheduleOneValue,
                PaymentMode.twoPayments => l10n.payScheduleTwoValue,
              },
      ),
      trailing: const _Chevron(),
      onTap: () async {
        final bloc = context.read<SettingsBloc>();
        await context.push<void>(AppRoutes.paySchedule);
        bloc.add(const SettingsRefreshed());
      },
    );
  }
}

class _CurrencyRow extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<SettingsBloc>().state;
    final loaded = state.status == SettingsStatus.ready;

    return ListTile(
      leading: const Icon(LucideIcons.arrowRightLeft),
      title: Text(l10n.defaultCurrencyTitle),
      subtitle: Text(loaded ? currencyLabel(l10n, state.currency) : '—'),
      trailing: const _Chevron(),
      enabled: loaded,
      onTap: () async {
        final bloc = context.read<SettingsBloc>();
        final currency = await showCurrencySheet(
          context,
          selected: state.currency,
        );
        if (currency != null) bloc.add(DefaultCurrencySelected(currency));
      },
    );
  }
}

class _ThemeRow extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final choice = context.select<ThemeBloc, ThemeChoice>(
      (bloc) => bloc.state.choice,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.themeTitle, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 8),
          PillSegmentedButton<ThemeChoice>(
            segments: [
              ButtonSegment(
                value: ThemeChoice.system,
                label: Text(l10n.themeSystem),
              ),
              ButtonSegment(
                value: ThemeChoice.light,
                label: Text(l10n.themeLight),
              ),
              ButtonSegment(
                value: ThemeChoice.dark,
                label: Text(l10n.themeDark),
              ),
            ],
            selected: {choice},
            onSelectionChanged: (selection) =>
                context.read<ThemeBloc>().add(ThemeSelected(selection.first)),
          ),
        ],
      ),
    );
  }
}

/// The language as a segmented control, like the theme; the choice applies at
/// once.
class _LanguageRow extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final selected = context.select<LanguageBloc, AppLanguage>(
      (bloc) => bloc.state.language,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.languageSectionTitle,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          PillSegmentedButton<AppLanguage>(
            segments: [
              ButtonSegment(
                value: AppLanguage.system,
                label: Text(l10n.languageSystemShort),
              ),
              ButtonSegment(
                value: AppLanguage.english,
                label: Text(l10n.languageEnglish),
              ),
              ButtonSegment(
                value: AppLanguage.arabic,
                label: Text(l10n.languageArabic),
              ),
            ],
            selected: {selected},
            onSelectionChanged: (selection) => context.read<LanguageBloc>().add(
              LanguageSelected(selection.first),
            ),
          ),
        ],
      ),
    );
  }
}

/// The notification permission and, below it, the reminder on the pay days.
class _Notifications extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return const NotificationsSettingsSection(footer: _ReminderSwitch());
  }
}

class _ReminderSwitch extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SettingsBloc>().state;

    return SwitchListTile(
      title: Text(context.l10n.remindOnPayDays),
      value: state.schedule.remindOnPayDays,
      onChanged: state.status == SettingsStatus.ready
          ? (remind) => context.read<SettingsBloc>().add(
              PayDayReminderToggled(remind: remind),
            )
          : null,
    );
  }
}

class _DataRows extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      children: [
        ListTile(
          leading: const Icon(LucideIcons.shapes),
          title: Text(l10n.categoriesTitle),
          trailing: const _Chevron(),
          onTap: () => context.push(AppRoutes.categories),
        ),
        ListTile(
          leading: const Icon(LucideIcons.wallet),
          title: Text(l10n.accountsTitle),
          trailing: const _Chevron(),
          onTap: () => context.push(AppRoutes.accounts),
        ),
        ListTile(
          leading: const Icon(LucideIcons.upload),
          title: Text(l10n.exportCsvTitle),
          onTap: () async {
            final request = await showCsvExportSheet(context);
            if (request == null || !context.mounted) return;
            final exported = await showCsvExportPasswordDialog(
              context,
              request: request,
            );
            if ((exported ?? false) && context.mounted) {
              showSuccessSnackBar(context, l10n.csvExportReady);
            }
          },
        ),
        ListTile(
          leading: const Icon(LucideIcons.download),
          title: Text(l10n.importCsvTitle),
          onTap: () => context.push(AppRoutes.importCsv),
        ),
      ],
    );
  }
}

/// "Where you are signed in" and "Security activity".
class _SecurityRows extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      children: [
        ListTile(
          leading: const Icon(LucideIcons.monitorSmartphone),
          title: Text(l10n.sessionsTitle),
          subtitle: Text(l10n.sessionsRowHint),
          trailing: const _Chevron(),
          onTap: () => context.push(AppRoutes.sessions),
        ),
        ListTile(
          leading: const Icon(LucideIcons.history),
          title: Text(l10n.securityActivityTitle),
          subtitle: Text(l10n.securityActivityRowHint),
          trailing: const _Chevron(),
          onTap: () => context.push(AppRoutes.securityActivity),
        ),
      ],
    );
  }
}

class _Version extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Text(
        context.l10n.appVersionLabel(version: appVersion),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
