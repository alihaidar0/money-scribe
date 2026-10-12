import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/routing/app_routes.dart';
import 'package:money_scribe/core/widgets/failure_snack_bar.dart';
import 'package:money_scribe/core/widgets/skeleton.dart';
import 'package:money_scribe/core/widgets/state_view.dart';
import 'package:money_scribe/features/auth/bloc/account_bloc.dart';
import 'package:money_scribe/features/auth/domain/account_profile.dart';
import 'package:money_scribe/features/auth/domain/auth_repository.dart';
import 'package:money_scribe/features/auth/presentation/widgets/account_dialogs.dart';

/// ST-2: the account: who the person is, and the rows that change the
/// password, sign out and delete the account (ST-6, ST-10, ST-11).
class AccountScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          AccountBloc(repository: context.read<AuthRepository>())
            ..add(const AccountStarted()),
      child: const _AccountView(),
    );
  }
}

/// The widest the page grows, so it stays readable on a wide screen.
const _maxContentWidth = 560.0;

class _AccountView extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bloc = context.read<AccountBloc>();
    final status = context.select<AccountBloc, AccountStatus>(
      (bloc) => bloc.state.status,
    );

    return BlocListener<AccountBloc, AccountState>(
      listenWhen: (previous, current) =>
          previous.action != current.action &&
          current.action == AccountAction.signOutFailed,
      listener: (context, state) => showFailureSnackBar(
        context,
        l10n.couldNotSignOut,
        onRetry: () => bloc.add(const SignOutConfirmed()),
      ),
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.accountTitle)),
        body: switch (status) {
          AccountStatus.loading => const _Skeleton(),
          AccountStatus.noConnection => FailureView(
            kind: FailureKind.noConnection,
            onRetry: () => bloc.add(const AccountRetried()),
          ),
          AccountStatus.failure => FailureView(
            kind: FailureKind.error,
            errorTitle: l10n.accountLoadFailed,
            onRetry: () => bloc.add(const AccountRetried()),
          ),
          AccountStatus.ready => const _Content(),
        },
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final profile = context.select<AccountBloc, AccountProfile>(
      (bloc) => bloc.state.profile!,
    );
    final isBusy = context.select<AccountBloc, bool>(
      (bloc) => bloc.state.isBusy,
    );

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxContentWidth),
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          children: [
            Center(
              child: Semantics(
                container: true,
                child: Column(
                  children: [
                    ExcludeSemantics(child: _Initial(profile.initial)),
                    const SizedBox(height: 16),
                    Text(
                      profile.name,
                      style: theme.textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    // An address reads from left to right in any language.
                    Text(
                      profile.email,
                      textDirection: TextDirection.ltr,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: Text(l10n.changePasswordTitle),
              trailing: const _Chevron(),
              onTap: () => context.push(AppRoutes.changePassword),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text(l10n.signOutAction),
              enabled: !isBusy,
              onTap: () => _signOut(context),
            ),
            const Divider(height: 32),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: theme.colorScheme.error,
              ),
              title: Text(
                l10n.deleteMyAccountAction,
                style: TextStyle(color: theme.colorScheme.error),
              ),
              enabled: !isBusy,
              onTap: () => showDeleteAccountDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    final bloc = context.read<AccountBloc>();
    if (await confirmSignOut(context)) bloc.add(const SignOutConfirmed());
  }
}

/// The round letter that stands in for a photo.
class _Initial extends StatelessWidget {
  const new(this.initial);

  final String initial;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 96,
      height: 96,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.primaryContainer,
      ),
      child: Text(
        initial,
        style: theme.textTheme.displaySmall?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
        ),
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
          ? Icons.chevron_left
          : Icons.chevron_right,
    );
  }
}

class _Skeleton extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return SkeletonScope(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const Center(child: SkeletonBox(height: 96, width: 96, radius: 48)),
          const SizedBox(height: 16),
          const Center(child: SkeletonBox(height: 24, width: 160)),
          const SizedBox(height: 8),
          const Center(child: SkeletonBox(height: 20, width: 220)),
          const SizedBox(height: 32),
          for (var i = 0; i < 3; i++) ...[
            const SkeletonBox(height: 56),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
