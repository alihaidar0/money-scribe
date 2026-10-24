import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:money_scribe/core/formatting/countdown_format.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/widgets/success_snack_bar.dart';
import 'package:money_scribe/features/auth/bloc/device_key_setting_bloc.dart';
import 'package:money_scribe/features/auth/domain/device_key.dart';
import 'package:money_scribe/features/auth/domain/device_key_repository.dart';
import 'package:money_scribe/features/auth/presentation/widgets/password_prompt_dialog.dart';

/// The "Sign in with fingerprint" row of the Settings. It is not the
/// fingerprint of the app lock: this one lets the phone sign the person in
/// again after signing out, with no password. Turning it on asks for the
/// password, then for a fingerprint; the PIN is never a way to sign in.
class FingerprintSignInTile extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          DeviceKeySettingBloc(repository: context.read<DeviceKeyRepository>())
            ..add(const DeviceKeySettingRefreshed()),
      child: const _Tile(),
    );
  }
}

class _Tile extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<DeviceKeySettingBloc>().state;
    // Turning it off is always possible, even on a phone that can no longer
    // hold the key.
    final canSwitch =
        !state.isBusy &&
        (state.canTurnOn || (state.isLoaded && state.isEnabled));

    return BlocListener<DeviceKeySettingBloc, DeviceKeySettingState>(
      listenWhen: (previous, current) =>
          previous.outcome != current.outcome && current.outcome != null,
      listener: _tell,
      child: SwitchListTile(
        title: Text(l10n.fingerprintSignInTitle),
        subtitle: Text(_hint(context, state)),
        secondary: const Icon(Icons.vpn_key_outlined),
        value: state.isEnabled,
        onChanged: canSwitch
            ? (turnedOn) => turnedOn ? _turnOn(context) : _turnOff(context)
            : null,
      ),
    );
  }

  String _hint(BuildContext context, DeviceKeySettingState state) {
    final l10n = context.l10n;
    if (state.isEnabled || !state.isLoaded) return l10n.fingerprintSignInHint;
    return switch (state.support) {
      DeviceKeySupport.available => l10n.fingerprintSignInHint,
      DeviceKeySupport.notEnrolled => l10n.fingerprintSettingUnavailable,
      DeviceKeySupport.unsupported => l10n.fingerprintSignInUnsupported,
    };
  }

  Future<void> _turnOn(BuildContext context) async {
    final bloc = context.read<DeviceKeySettingBloc>();
    final l10n = context.l10n;
    final password = await showPasswordPrompt(
      context,
      title: l10n.fingerprintSignInPromptTitle,
      message: l10n.fingerprintSignInPromptMessage,
      actionLabel: l10n.fingerprintSignInPromptAction,
    );
    if (password == null) return;
    bloc.add(
      FingerprintSignInTurnedOn(
        password: password,
        prompt: l10n.fingerprintSignInReason,
      ),
    );
  }

  void _turnOff(BuildContext context) {
    context.read<DeviceKeySettingBloc>().add(
      const FingerprintSignInTurnedOff(),
    );
  }

  void _tell(BuildContext context, DeviceKeySettingState state) {
    final l10n = context.l10n;
    final outcome = state.outcome;
    if (outcome == null) return;

    switch (outcome) {
      case DeviceKeyOutcome.turnedOn:
        showSuccessSnackBar(context, l10n.fingerprintSignInTurnedOn);
        return;
      case DeviceKeyOutcome.turnedOff:
        showSuccessSnackBar(context, l10n.fingerprintSignInTurnedOff);
        return;
      case DeviceKeyOutcome.wrongPassword ||
          DeviceKeyOutcome.notMatched ||
          DeviceKeyOutcome.refused ||
          DeviceKeyOutcome.limitReached ||
          DeviceKeyOutcome.expired ||
          DeviceKeyOutcome.cannotCheck ||
          DeviceKeyOutcome.waitForPassword ||
          DeviceKeyOutcome.busy ||
          DeviceKeyOutcome.offline ||
          DeviceKeyOutcome.failed:
        break;
    }
    final message = switch (outcome) {
      DeviceKeyOutcome.wrongPassword => l10n.fingerprintSignInWrongPassword,
      DeviceKeyOutcome.notMatched => l10n.fingerprintNotTurnedOn,
      DeviceKeyOutcome.refused => l10n.fingerprintSignInRefused,
      DeviceKeyOutcome.limitReached => l10n.fingerprintSignInLimit,
      DeviceKeyOutcome.expired => l10n.fingerprintSignInExpired,
      DeviceKeyOutcome.cannotCheck => l10n.fingerprintSignInCannotCheck,
      DeviceKeyOutcome.waitForPassword => l10n.fingerprintSignInWait(
        time: formatCountdown(state.waitSeconds),
      ),
      DeviceKeyOutcome.busy => l10n.fingerprintSignInBusy,
      DeviceKeyOutcome.offline => l10n.fingerprintSignInOffline,
      _ => l10n.fingerprintSignInFailed,
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
