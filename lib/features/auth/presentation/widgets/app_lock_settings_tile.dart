import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/routing/app_routes.dart';
import 'package:money_scribe/features/auth/bloc/app_lock_setting_bloc.dart';
import 'package:money_scribe/features/auth/domain/app_lock_repository.dart';

/// The App lock switch of the Settings. Turning it on asks for a PIN on the
/// Create a PIN screen; turning it off forgets the PIN.
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
    final state = context.watch<AppLockSettingBloc>().state;

    return SwitchListTile(
      title: Text(context.l10n.appLockTitle),
      secondary: const Icon(Icons.lock_outline),
      value: state.isEnabled,
      onChanged: state.isBusy
          ? null
          : (turnedOn) => turnedOn ? _createPin(context) : _turnOff(context),
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
}
