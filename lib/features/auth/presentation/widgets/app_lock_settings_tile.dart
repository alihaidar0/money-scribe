import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/routing/app_routes.dart';
import 'package:money_scribe/features/auth/bloc/app_lock_setting_bloc.dart';
import 'package:money_scribe/features/auth/domain/app_lock_repository.dart';
import 'package:money_scribe/features/auth/domain/lock_timeout.dart';

/// The App lock rows of the Settings: the switch, and, while the lock is on,
/// how long the app may stay in the background before it locks. Turning the
/// lock on asks for a PIN on the Create a PIN screen; turning it off forgets
/// the PIN.
class AppLockSettingsTile extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          AppLockSettingBloc(repository: context.read<AppLockRepository>())
            ..add(const AppLockSettingRefreshed()),
      child: const _AppLockTile(),
    );
  }
}

class _AppLockTile extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<AppLockSettingBloc>().state;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SwitchListTile(
          title: Text(l10n.appLockTitle),
          secondary: const Icon(Icons.lock_outline),
          value: state.isEnabled,
          onChanged: state.isBusy
              ? null
              : (turnedOn) =>
                    turnedOn ? _createPin(context) : _turnOff(context),
        ),
        if (state.isEnabled)
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: Text(l10n.lockTimeoutTitle),
            subtitle: Text(_label(l10n, state.timeout)),
            enabled: !state.isBusy,
            onTap: () => _chooseTimeout(context, state.timeout),
          ),
      ],
    );
  }

  Future<void> _createPin(BuildContext context) async {
    final bloc = context.read<AppLockSettingBloc>();
    await context.push<void>(AppRoutes.createPin);
    bloc.add(const AppLockSettingRefreshed());
  }

  void _turnOff(BuildContext context) {
    context.read<AppLockSettingBloc>().add(const AppLockTurnedOff());
  }

  Future<void> _chooseTimeout(BuildContext context, LockTimeout current) async {
    final bloc = context.read<AppLockSettingBloc>();
    final l10n = context.l10n;
    final chosen = await showDialog<LockTimeout>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(l10n.lockTimeoutTitle),
        children: [
          RadioGroup<LockTimeout>(
            groupValue: current,
            onChanged: (value) => Navigator.of(dialogContext).pop(value),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final timeout in LockTimeout.values)
                  RadioListTile<LockTimeout>(
                    value: timeout,
                    title: Text(_label(l10n, timeout)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    if (chosen != null) bloc.add(AppLockTimeoutChosen(chosen));
  }

  static String _label(AppLocalizations l10n, LockTimeout timeout) {
    return switch (timeout) {
      LockTimeout.immediately => l10n.lockTimeoutImmediately,
      LockTimeout.thirtySeconds => l10n.lockTimeoutThirtySeconds,
      LockTimeout.oneMinute => l10n.lockTimeoutOneMinute,
      LockTimeout.fiveMinutes => l10n.lockTimeoutFiveMinutes,
    };
  }
}
