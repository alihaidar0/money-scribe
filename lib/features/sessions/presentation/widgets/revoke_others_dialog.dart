import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:money_scribe/core/formatting/countdown_format.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/time/ticker.dart';
import 'package:money_scribe/core/widgets/button_spinner.dart';
import 'package:money_scribe/core/widgets/password_field.dart';
import 'package:money_scribe/features/sessions/bloc/revoke_others_bloc.dart';
import 'package:money_scribe/features/sessions/domain/sessions_repository.dart';

/// ST-12e: asks for the password and signs the other devices out. [count] is
/// how many devices will be signed out. Closes with what was done, or with
/// `null` when cancelled. The dialog stays open while the password is wrong, so
/// the person can type it again.
Future<OthersSignedOut?> showRevokeOthersDialog(
  BuildContext context, {
  required int count,
}) {
  return showDialog<OthersSignedOut>(
    context: context,
    builder: (dialogContext) => BlocProvider(
      create: (_) => RevokeOthersBloc(
        repository: context.read<SessionsRepository>(),
        ticker: context.read<Ticker>(),
      ),
      child: _RevokeOthersDialog(count: count),
    ),
  );
}

class _RevokeOthersDialog extends StatefulWidget {
  const new({required this.count});

  final int count;

  @override
  State<_RevokeOthersDialog> createState() => _RevokeOthersDialogState();
}

class _RevokeOthersDialogState extends State<_RevokeOthersDialog> {
  final _password = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bloc = context.read<RevokeOthersBloc>();

    return BlocConsumer<RevokeOthersBloc, RevokeOthersState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == RevokeOthersStatus.done,
      listener: (context, state) => Navigator.of(context).pop(state.result),
      builder: (context, state) {
        final busy = state.status == RevokeOthersStatus.revoking;
        final waiting = state.status == RevokeOthersStatus.waiting;

        return AlertDialog(
          title: Text(l10n.revokeOthersTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.revokeOthersMessage(count: widget.count)),
                const SizedBox(height: 16),
                PasswordField(
                  controller: _password,
                  label: l10n.passwordLabel,
                  enabled: !busy,
                  textInputAction: TextInputAction.done,
                  showErrorOutline: _error(l10n, state) != null,
                  errorText: _error(l10n, state),
                  onChanged: (text) =>
                      bloc.add(RevokeOthersPasswordEdited(text)),
                  onSubmitted: (_) => bloc.add(const RevokeOthersSubmitted()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancelAction),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              onPressed: state.password.isEmpty || busy || waiting
                  ? null
                  : () => bloc.add(const RevokeOthersSubmitted()),
              child: busy
                  ? const ButtonSpinner()
                  : Text(
                      waiting
                          ? l10n.tryAgainIn(
                              time: formatCountdown(state.waitSecondsLeft),
                            )
                          : l10n.revokeOthersConfirm,
                    ),
            ),
          ],
        );
      },
    );
  }

  /// What is wrong under the password, if anything.
  String? _error(AppLocalizations l10n, RevokeOthersState state) {
    return switch (state.status) {
      RevokeOthersStatus.wrongPassword => l10n.revokeOthersWrongPassword,
      RevokeOthersStatus.unavailable ||
      RevokeOthersStatus.noConnection ||
      RevokeOthersStatus.failure => l10n.revokeOthersFailed,
      _ => null,
    };
  }
}
