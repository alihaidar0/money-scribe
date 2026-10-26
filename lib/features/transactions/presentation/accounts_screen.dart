import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/widgets/failure_snack_bar.dart';
import 'package:money_scribe/core/widgets/icon_circle.dart';
import 'package:money_scribe/core/widgets/skeleton.dart';
import 'package:money_scribe/core/widgets/state_view.dart';
import 'package:money_scribe/features/transactions/bloc/accounts_bloc.dart';
import 'package:money_scribe/features/transactions/domain/account.dart';
import 'package:money_scribe/features/transactions/domain/accounts_repository.dart';
import 'package:money_scribe/features/transactions/presentation/account_icons.dart';
import 'package:money_scribe/features/transactions/presentation/widgets/account_form_sheet.dart';

/// ST-5: the accounts, such as a card and cash. A row opens a sheet to change
/// or delete the account (ST-5b); the button adds one.
class AccountsScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          AccountsBloc(repository: context.read<AccountsRepository>())
            ..add(const AccountsStarted()),
      child: const _AccountsView(),
    );
  }
}

class _AccountsView extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bloc = context.read<AccountsBloc>();
    final status = context.select<AccountsBloc, AccountsStatus>(
      (bloc) => bloc.state.status,
    );

    return MultiBlocListener(
      listeners: [
        BlocListener<AccountsBloc, AccountsState>(
          listenWhen: (previous, current) =>
              previous.failedAction != current.failedAction &&
              current.failedAction != null,
          listener: (context, state) {
            final action = state.failedAction;
            if (action == null) return;
            showFailureSnackBar(
              context,
              action is AccountDeleted
                  ? l10n.couldNotDelete
                  : l10n.couldNotSave,
              onRetry: () => bloc.add(action),
            );
          },
        ),
        BlocListener<AccountsBloc, AccountsState>(
          listenWhen: (previous, current) =>
              previous.staleAction != current.staleAction &&
              current.staleAction != null,
          listener: (context, state) {
            final action = state.staleAction;
            if (action == null) return;
            // An account that is gone has nothing to apply the change to.
            final id = switch (action) {
              AccountChanged(:final id) || AccountDeleted(:final id) => id,
              _ => null,
            };
            final gone = !state.accounts.any((account) => account.id == id);
            showFailureSnackBar(
              context,
              l10n.itemChangedElsewhere,
              actionLabel: l10n.applyAgainAction,
              onRetry: gone ? null : () => bloc.add(action),
            );
          },
        ),
        BlocListener<AccountsBloc, AccountsState>(
          listenWhen: (previous, current) =>
              previous.refusal != current.refusal && current.refusal != null,
          listener: (context, state) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(switch (state.refusal) {
                    AccountRefusal.nameTaken => l10n.accountNameTaken,
                    AccountRefusal.limitReached => l10n.accountLimitReached,
                    null => '',
                  }),
                ),
              );
          },
        ),
        BlocListener<AccountsBloc, AccountsState>(
          listenWhen: (previous, current) =>
              !previous.deleteBlocked && current.deleteBlocked,
          listener: (context, state) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(l10n.accountInUse)));
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.accountsTitle)),
        floatingActionButton: status == AccountsStatus.ready
            ? FloatingActionButton.extended(
                heroTag: null,
                onPressed: () => _add(context),
                icon: const Icon(Icons.add),
                label: Text(l10n.addAccountAction),
              )
            : null,
        body: switch (status) {
          AccountsStatus.loading => const _Skeleton(),
          AccountsStatus.noConnection => FailureView(
            kind: FailureKind.noConnection,
            onRetry: () => bloc.add(const AccountsRetried()),
          ),
          AccountsStatus.failure => FailureView(
            kind: FailureKind.error,
            errorTitle: l10n.accountsLoadFailed,
            onRetry: () => bloc.add(const AccountsRetried()),
          ),
          AccountsStatus.ready => const _List(),
        },
      ),
    );
  }

  Future<void> _add(BuildContext context) async {
    final bloc = context.read<AccountsBloc>();
    final result = await showAccountFormSheet(
      context,
      takenNames: _takenNames(bloc.state.accounts),
    );
    if (result is AccountFormSaved) bloc.add(AccountAdded(result.draft));
  }
}

/// The names of [accounts] in lower case, except the one of [except].
Set<String> _takenNames(List<Account> accounts, {String? except}) {
  return {
    for (final account in accounts)
      if (account.id != except) account.name.toLowerCase(),
  };
}

class _List extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final accounts = context.select<AccountsBloc, List<Account>>(
      (bloc) => bloc.state.accounts,
    );

    if (accounts.isEmpty) {
      return StateView(
        icon: Icons.account_balance_wallet_outlined,
        title: l10n.accountsEmptyTitle,
        actionLabel: l10n.addAccountAction,
        filledAction: true,
        onAction: () async {
          final bloc = context.read<AccountsBloc>();
          final result = await showAccountFormSheet(
            context,
            takenNames: _takenNames(bloc.state.accounts),
          );
          if (result is AccountFormSaved) bloc.add(AccountAdded(result.draft));
        },
      );
    }

    return ListView(
      // Room under the last row for the button.
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        for (final account in accounts)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _AccountRow(account: account),
          ),
      ],
    );
  }
}

/// An account: its icon and name. The whole row opens its sheet.
class _AccountRow extends StatelessWidget {
  const new({required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      child: Material(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _edit(context),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 8, 8),
              child: Row(
                children: [
                  IconCircle(icon: accountIcon(account.kind), size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(account.name, style: theme.textTheme.bodyLarge),
                  ),
                  ExcludeSemantics(
                    child: IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: l10n.editItemTooltip(name: account.name),
                      onPressed: () => _edit(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context) async {
    final bloc = context.read<AccountsBloc>();
    final result = await showAccountFormSheet(
      context,
      account: account,
      takenNames: _takenNames(bloc.state.accounts, except: account.id),
    );
    switch (result) {
      case AccountFormSaved(:final draft):
        bloc.add(AccountChanged(account.id, draft));
      case AccountFormDeleted():
        bloc.add(AccountDeleted(account.id));
      case null:
        break;
    }
  }
}

class _Skeleton extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return SkeletonScope(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          for (var i = 0; i < 3; i++) ...[
            const SkeletonBox(),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
