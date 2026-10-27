import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:money_scribe/core/formatting/countdown_format.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/time/ticker.dart';
import 'package:money_scribe/core/widgets/button_spinner.dart';
import 'package:money_scribe/core/widgets/message_banner.dart';
import 'package:money_scribe/core/widgets/password_field.dart';
import 'package:money_scribe/features/settings/bloc/csv_export_password_bloc.dart';
import 'package:money_scribe/features/settings/domain/csv_transfer.dart';
import 'package:money_scribe/features/settings/domain/csv_transfer_repository.dart';

/// ST-7b and ST-7c: asks for the password, then makes the file of [request]
/// and opens the share sheet. Closes with `true` once the file is shared, or
/// with `null` when cancelled. The dialog stays open while the password is
/// wrong, and while too many attempts (or exports) lock it with a countdown.
Future<bool?> showCsvExportPasswordDialog(
  BuildContext context, {
  required CsvExportRequest request,
}) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => BlocProvider(
      create: (_) => CsvExportPasswordBloc(
        repository: context.read<CsvTransferRepository>(),
        ticker: context.read<Ticker>(),
        request: request,
      ),
      child: const _CsvExportPasswordDialog(),
    ),
  );
}

class _CsvExportPasswordDialog extends StatefulWidget {
  const new();

  @override
  State<_CsvExportPasswordDialog> createState() =>
      _CsvExportPasswordDialogState();
}

class _CsvExportPasswordDialogState extends State<_CsvExportPasswordDialog> {
  final _password = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bloc = context.read<CsvExportPasswordBloc>();

    return BlocConsumer<CsvExportPasswordBloc, CsvExportPasswordState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == CsvExportPasswordStatus.done,
      listener: (context, state) => Navigator.of(context).pop(true),
      builder: (context, state) {
        final busy = state.status == CsvExportPasswordStatus.exporting;
        final waiting = state.status == CsvExportPasswordStatus.waiting;
        final error = _error(l10n, state);
        final countdown = formatCountdown(state.waitSecondsLeft);

        return AlertDialog(
          title: Text(l10n.csvExportPasswordTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.csvExportPasswordMessage),
                const SizedBox(height: 16),
                PasswordField(
                  controller: _password,
                  label: l10n.passwordLabel,
                  enabled: !busy && !waiting,
                  textInputAction: TextInputAction.done,
                  showErrorOutline: error != null,
                  errorText: error,
                  onChanged: (text) => bloc.add(CsvExportPasswordEdited(text)),
                  onSubmitted: (_) =>
                      bloc.add(const CsvExportPasswordSubmitted()),
                ),
                if (waiting) ...[
                  const SizedBox(height: 16),
                  MessageBanner(
                    icon: Icons.lock_outline,
                    text: l10n.csvExportLocked(time: countdown),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancelAction),
            ),
            FilledButton(
              onPressed: state.password.isEmpty || busy || waiting
                  ? null
                  : () => bloc.add(const CsvExportPasswordSubmitted()),
              child: busy
                  ? const ButtonSpinner()
                  : Text(
                      waiting
                          ? l10n.tryAgainIn(time: countdown)
                          : l10n.exportAction,
                    ),
            ),
          ],
        );
      },
    );
  }

  /// What is wrong under the password, if anything.
  String? _error(AppLocalizations l10n, CsvExportPasswordState state) {
    return switch (state.status) {
      CsvExportPasswordStatus.wrongPassword => l10n.csvExportWrongPassword,
      CsvExportPasswordStatus.unavailable => l10n.csvExportBusy,
      CsvExportPasswordStatus.noConnection => l10n.couldNotExport,
      CsvExportPasswordStatus.failure => l10n.csvExportFailed,
      _ => null,
    };
  }
}
